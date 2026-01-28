# frozen_string_literal: true

require 'rails/generators'
require 'yaml'
require 'fileutils'

module Modulorails

  class TraefikMigrationGenerator < Rails::Generators::Base

    source_root File.expand_path('templates', __dir__)

    desc 'This generator migrates an existing project to use Traefik'

    class_option :backup, type: :boolean, default: true,
                 desc: 'Create a backup of existing files before migration'

    def check_prerequisites
      @project_name = Modulorails.data.name.parameterize
      @adapter = Modulorails.data.adapter

      say 'Checking prerequisites...'

      # Check for existing compose files
      @compose_file = find_compose_file
      unless @compose_file
        say_status :error, 'No compose file found (compose.yml or docker-compose.yml)', :red
        raise 'No compose file found'
      end

      say_status :found, "Compose file: #{@compose_file}", :green
    end

    def create_backup
      return unless options[:backup]

      @backup_dir = Rails.root.join(".traefik-migration-backup-#{Time.now.strftime('%Y%m%d-%H%M%S')}")
      FileUtils.mkdir_p(@backup_dir)

      say "Creating backup in #{@backup_dir}..."

      # Backup compose file
      FileUtils.cp(@compose_file, @backup_dir) if File.exist?(@compose_file)

      # Backup devcontainer files
      devcontainer_compose = Rails.root.join('.devcontainer/compose.yml')
      devcontainer_json = Rails.root.join('.devcontainer/devcontainer.json')
      FileUtils.cp(devcontainer_compose, @backup_dir) if File.exist?(devcontainer_compose)
      FileUtils.cp(devcontainer_json, @backup_dir) if File.exist?(devcontainer_json)

      # Backup .env
      env_file = Rails.root.join('.env')
      FileUtils.cp(env_file, @backup_dir) if File.exist?(env_file)

      say_status :backup, "Files backed up to #{@backup_dir}", :green
    end

    def create_env_file
      env_file = Rails.root.join('.env')

      if File.exist?(env_file)
        content = File.read(env_file)
        unless content.include?('COMPOSE_PROJECT_NAME')
          say 'Adding COMPOSE_PROJECT_NAME to existing .env...'
          append_to_file env_file, "\nCOMPOSE_PROJECT_NAME=#{@project_name}\n"
        end
      else
        say 'Creating .env file...'
        create_file '.env', "COMPOSE_PROJECT_NAME=#{@project_name}\n"
      end
    end

    def create_docker_networks
      say 'Creating Docker networks...'

      system('docker network create traefik-proxy 2>/dev/null') || true
      system('docker network create development 2>/dev/null') || true

      say_status :create, 'Docker networks (traefik-proxy, development)', :green
    end

    def migrate_compose_file
      say "Migrating #{@compose_file}..."

      content = File.read(@compose_file)
      compose_data = YAML.safe_load(content, permitted_classes: [Symbol])

      # Add networks if not present
      compose_data['networks'] ||= {}
      compose_data['networks']['development'] = { 'external' => true, 'name' => 'development' }
      compose_data['networks']['traefik-proxy'] = { 'external' => true, 'name' => 'traefik-proxy' }
      compose_data['networks']['default'] = nil

      # Migrate services
      if compose_data['services']
        migrate_app_service(compose_data['services']['app']) if compose_data['services']['app']
        migrate_database_service(compose_data['services']['database']) if compose_data['services']['database']
        migrate_redis_service(compose_data['services']['redis']) if compose_data['services']['redis']
        migrate_mailcatcher_service(compose_data['services']['mailcatcher']) if compose_data['services']['mailcatcher']
        migrate_minio_service(compose_data['services']['minio']) if compose_data['services']['minio']
        migrate_webpack_service(compose_data['services']['webpack']) if compose_data['services']['webpack']
        migrate_sidekiq_service(compose_data['services']['sidekiq']) if compose_data['services']['sidekiq']
      end

      # Write updated file
      File.write(@compose_file, compose_data.to_yaml)

      say_status :migrate, @compose_file, :green
    end

    def migrate_devcontainer
      devcontainer_compose = Rails.root.join('.devcontainer/compose.yml')
      devcontainer_json = Rails.root.join('.devcontainer/devcontainer.json')

      return unless File.exist?(devcontainer_compose)

      say 'Migrating devcontainer configuration...'

      # Migrate compose.yml
      content = File.read(devcontainer_compose)
      compose_data = YAML.safe_load(content, permitted_classes: [Symbol])

      compose_data['networks'] ||= {}
      compose_data['networks']['development'] = { 'external' => true, 'name' => 'development' }
      compose_data['networks']['traefik-proxy'] = { 'external' => true, 'name' => 'traefik-proxy' }
      compose_data['networks']['default'] = nil

      if compose_data['services']
        migrate_app_service(compose_data['services']['app']) if compose_data['services']['app']
        migrate_database_service(compose_data['services']['database']) if compose_data['services']['database']
        migrate_redis_service(compose_data['services']['redis']) if compose_data['services']['redis']
        migrate_mailcatcher_service(compose_data['services']['mailcatcher']) if compose_data['services']['mailcatcher']
        migrate_minio_service(compose_data['services']['minio']) if compose_data['services']['minio']
      end

      File.write(devcontainer_compose, compose_data.to_yaml)

      # Migrate devcontainer.json
      if File.exist?(devcontainer_json)
        migrate_devcontainer_json(devcontainer_json)
      end

      say_status :migrate, 'devcontainer configuration', :green
    end

    def print_post_migration_instructions
      say ''
      say '=' * 60
      say 'Migration Complete!'
      say '=' * 60
      say ''
      say 'Next steps:'
      say ''
      say '1. Ensure Traefik is running:'
      say '   cd ~/traefik && docker compose up -d'
      say ''
      say '2. Restart your project:'
      say '   rails-stop && rails-dev'
      say ''
      say '3. Access your application at:'
      say "   http://#{@project_name}.localhost"
      say ''
      if @backup_dir
        say 'Rollback (if needed):'
        say "   cp #{@backup_dir}/* ."
        say ''
      end
      say '=' * 60
    end

    private

    def find_compose_file
      %w[compose.yml docker-compose.yml].each do |file|
        path = Rails.root.join(file)
        return path if File.exist?(path)
      end
      nil
    end

    def migrate_app_service(service)
      # Remove exposed ports
      service.delete('ports')

      # Add networks
      service['networks'] = %w[default development traefik-proxy]

      # Add Traefik labels
      service['labels'] ||= []
      service['labels'] = [
        'traefik.enable=true',
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-app.rule=Host(`${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost`)",
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-app.entrypoints=web",
        "traefik.http.services.${COMPOSE_PROJECT_NAME:-#{@project_name}}-app.loadbalancer.server.port=3000"
      ]

      # Update URL environment variable
      if service['environment'].is_a?(Hash)
        service['environment']['URL'] = "http://${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost"
      elsif service['environment'].is_a?(Array)
        service['environment'].reject! { |e| e.start_with?('URL=') }
        service['environment'] << "URL=http://${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost"
      end
    end

    def migrate_database_service(service)
      service.delete('ports')
      service['networks'] = ['default']
    end

    def migrate_redis_service(service)
      service.delete('ports')
      service['networks'] = ['default']
    end

    def migrate_mailcatcher_service(service)
      service.delete('ports')
      service['networks'] = %w[default traefik-proxy]
      service['labels'] = [
        'traefik.enable=true',
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-mail.rule=Host(`mail.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost`)",
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-mail.entrypoints=web",
        "traefik.http.services.${COMPOSE_PROJECT_NAME:-#{@project_name}}-mail.loadbalancer.server.port=1080"
      ]
    end

    def migrate_minio_service(service)
      service.delete('ports')
      service['networks'] = %w[default traefik-proxy]

      # Update environment
      if service['environment'].is_a?(Hash)
        service['environment']['MINIO_DOMAIN'] = "s3.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost"
        service['environment']['MINIO_SERVER_URL'] = "http://s3.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost"
      elsif service['environment'].is_a?(Array)
        service['environment'].reject! { |e| e.start_with?('MINIO_DOMAIN=') || e.start_with?('MINIO_SERVER_URL=') }
        service['environment'] << "MINIO_DOMAIN=s3.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost"
        service['environment'] << "MINIO_SERVER_URL=http://s3.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost"
      end

      service['labels'] = [
        'traefik.enable=true',
        # MinIO Console
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-minio-console.rule=Host(`minio.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost`)",
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-minio-console.entrypoints=web",
        "traefik.http.services.${COMPOSE_PROJECT_NAME:-#{@project_name}}-minio-console.loadbalancer.server.port=9001",
        # MinIO API
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-minio-api.rule=Host(`s3.${COMPOSE_PROJECT_NAME:-#{@project_name}}.localhost`)",
        "traefik.http.routers.${COMPOSE_PROJECT_NAME:-#{@project_name}}-minio-api.entrypoints=web",
        "traefik.http.services.${COMPOSE_PROJECT_NAME:-#{@project_name}}-minio-api.loadbalancer.server.port=9000"
      ]
    end

    def migrate_webpack_service(service)
      service.delete('ports')
      service['networks'] = ['default']
    end

    def migrate_sidekiq_service(service)
      service['networks'] = ['default']
    end

    def migrate_devcontainer_json(file_path)
      content = File.read(file_path)

      # Update name to use COMPOSE_PROJECT_NAME
      content.gsub!(/"name":\s*"[^"]+"/, "\"name\": \"${localEnv:COMPOSE_PROJECT_NAME:#{@project_name}}\"")

      # Clear forwardPorts
      content.gsub!(/"forwardPorts":\s*\[[^\]]*\]/, '"forwardPorts": []')

      # Add COMPOSE_PROJECT_NAME to remoteEnv if not present
      unless content.include?('COMPOSE_PROJECT_NAME')
        content.gsub!(
          /"remoteEnv":\s*\{/,
          "\"remoteEnv\": {\n    \"COMPOSE_PROJECT_NAME\": \"${localEnv:COMPOSE_PROJECT_NAME:#{@project_name}}\","
        )
      end

      File.write(file_path, content)
    end

  end

end
