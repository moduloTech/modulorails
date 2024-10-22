# frozen_string_literal: true

require 'modulorails/generators/base'

class Modulorails::DockerGenerator < Modulorails::Generators::Base

  VERSION = 2

  desc 'This generator creates Docker configuration for an app'

  protected

  def create_config
    @data = Modulorails.data
    @adapter = @data.adapter
    @webpack_container_needed = @data.webpacker_version.present?
    @image_name = @data.name.parameterize
    @environment_name = @data.environment_name

    create_dockerfile
    create_dockerfile_prod
    create_compose_yml
    create_docker_entrypoint
    template 'config/database.yml'
    template 'config/cable.yml'
    template 'config/initializers/0_redis.rb'
    template 'config/puma.rb'

    # Useless unless project is using Webpacker
    return unless @webpack_container_needed

    create_webpack_entrypoint
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate Docker configuration: #{e.message}")
  end

  private

  def create_dockerfile
    say('WARNING: The entrypoint was moved. Check that your Dockerfile still works.') if File.exist?('Dockerfile')
    template 'dockerfiles/modulotech/Dockerfile', 'Dockerfile'
  end

  def create_webpack_entrypoint
    create_new_file('entrypoints/webpack-entrypoint.sh', 'bin/webpack-entrypoint')
  end

  def create_docker_entrypoint
    create_new_file 'entrypoints/docker-entrypoint.sh', 'bin/docker-entrypoint'
  end

  def create_compose_yml
    create_new_file 'docker-compose.yml', 'compose.yml', executable: false
  end

  def create_dockerfile_prod
    if File.exist?('Dockerfile.prod')
      say('WARNING: The entrypoint was moved. Check that your Dockerfile.prod still works.')
    end

    if Gem::Version.new(@data.rails_version) >= Gem::Version.new('7.2')
      template 'dockerfiles/rails/Dockerfile.prod', 'Dockerfile.prod'
    else
      template 'dockerfiles/modulotech/Dockerfile.prod', 'Dockerfile.prod'
    end
  end

  def create_new_file(old_file, new_file, executable: true)
    if File.exist?(old_file)
      copy_file old_file, new_file
      remove_file old_file
    else
      template old_file, new_file
    end
    chmod new_file, 0o755 if executable
  end

end
