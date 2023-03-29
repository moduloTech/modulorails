# frozen_string_literal: true

require 'rails/generators'

class Modulorails::SidekiqGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)

  desc 'This generator adds Sidekiq to the project'

  def add_to_docker_compose
    add_to_docker_compose_yml_file(Rails.root.join('docker-compose.yml'))
  end

  def add_to_docker_compose_prod
    add_to_docker_compose_yml_file(Rails.root.join('docker-compose.prod.yml'))
  end

  def add_to_deploy_files
    add_to_deploy_file(Rails.root.join('config/deploy/production.yaml'))
    add_to_deploy_file(Rails.root.join('config/deploy/staging.yaml'))
    add_to_deploy_file(Rails.root.join('config/deploy/review.yaml'))
  end

  def add_to_gemfile
    gemfile_path = Rails.root.join('Gemfile')

    # Add gem redis unless already present
    unless File.read(gemfile_path).match?(/^\s*gem ['"]redis['"]/)
      append_to_file(gemfile_path, "gem 'redis'\n")
    end

    # Add gem sidekiq unless already present
    unless File.read(gemfile_path).match?(/^\s*gem ['"]sidekiq['"]/)
      append_to_file(gemfile_path, "gem 'sidekiq'\n")
    end
  end

  def add_to_config
    Dir.glob(Rails.root.join('config/environments/*.rb')) do |file|
      add_to_config_file(file)
    end
  end

  def add_initializer
    template 'config/initializers/sidekiq.rb'
  end

  def add_routes
    routes_path = Rails.root.join('config/routes.rb')

    unless File.read(routes_path).match?(%r{require ['"]sidekiq/web["']})
      inject_into_file routes_path, after: "Rails.application.routes.draw do\n" do
        <<-RUBY
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

        RUBY
      end
    end
  end

  def add_health_check
    file_path = Rails.root.join('config/initializers/health_check.rb')

    unless File.read(file_path).match?(%r{add_custom_check\s*\(?\s*['"]sidekiq-queues['"]\s*\)?})
      inject_into_file file_path, after: /^HealthCheck.setup do \|config\|\n$/ do
        <<-RUBY

  # Add one or more custom checks that return a blank string if ok, or an error message if there is an error
  config.add_custom_check('sidekiq-queues') do
    queues = Sidekiq::Queue.all

    # No queues, means no jobs, ok!
    next '' if queues.empty?

    enqueued_jobs_count = queues.each.map { |queue| queue.count }.sum

    # Less than 200 enqueued jobs, ok!
    enqueued_jobs_count < 200 ? '' : "\#{enqueued_jobs_count} are currently enqueued."
  end

  # Add one or more custom checks that return a blank string if ok, or an error message if there is an error
  config.add_custom_check('sidekiq-retries') do
    retry_jobs_count = Sidekiq::RetrySet.new.count

    # Less than 200 jobs to retry, ok!
    retry_jobs_count < 200 ? '' : "\#{retry_jobs_count} are waiting for retry."
  end
        RUBY
      end
    end
  end

  def add_entrypoint
    template 'entrypoints/sidekiq-entrypoint.sh'
    chmod 'entrypoints/sidekiq-entrypoint.sh', 0755
  end

  private

  def add_to_docker_compose_yml_file(file_path)
    @image_name ||= Modulorails.data.name.parameterize

    # Create docker-compose.yml unless present
    unless File.exist?(file_path)
      # Modulorails::GitlabciGenerator.new([], {}, {}).invoke_all
      invoke(Modulorails::DockerGenerator, [])
    end

    return if File.read(file_path).match?(/^ {2}sidekiq:$/)

    insert_into_file file_path, after: /^services:/ do
      <<-YAML

  sidekiq:
    image: modulotechgroup/#{@image_name}:dev
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      - database
      - redis
    volumes:
      - .:/app
    environment:
      RAILS_ENV: development
      URL: http://app:3000
      #{@image_name.upcase}_DATABASE_HOST: database
      #{@image_name.upcase}_DATABASE_NAME: #{@image_name}
      REDIS_URL: redis://redis:6379/1
    entrypoint: ./entrypoints/sidekiq-entrypoint.sh
    stdin_open: true
    tty: true
      YAML
    end
  end

  def add_to_config_file(file_path)
    pattern = /^(?>\s*)(?>#\s*)?(\w+)\.active_job\.queue_adapter = .+$/

    if File.read(file_path).match?(pattern)
      gsub_file file_path, pattern, '  \1.active_job.queue_adapter = :sidekiq'
    else
      append_file file_path, after: "configure do\n" do
        <<-RUBY
  config.active_job.queue_adapter = :sidekiq
        RUBY
      end
    end
  end

  def add_to_deploy_file(file_path)
    # Do nothing if file does not exists or Sidekiq is already enabled
    return if !File.exist?(file_path) || File.read(file_path).match?(/^ {2}sidekiq:$/)

    # Add sidekiq to deploy file
    insert_into_file file_path do
      <<-YAML

sidekiq:
  enabled: true
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 100m
      memory: 512Mi
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80
      YAML
    end
  end
end
