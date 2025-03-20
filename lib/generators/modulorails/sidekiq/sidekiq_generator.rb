# frozen_string_literal: true

require 'rails/generators'

class Modulorails::SidekiqGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)

  desc 'This generator adds Sidekiq to the project'

  def add_to_docker_compose
    add_to_docker_compose_yml_file(Rails.root.join('.devcontainer/compose.yml'))
  end

  def add_to_deploy_files
    add_to_deploy_file(Rails.root.join('config/deploy/production.yaml'))
    add_to_deploy_file(Rails.root.join('config/deploy/staging.yaml'))
    add_to_deploy_file(Rails.root.join('config/deploy/review.yaml'))
  end

  def add_to_gemfile
    gemfile_path = Rails.root.join('Gemfile')

    # Add gem redis unless already present
    append_to_file(gemfile_path, "\ngem 'redis'\n") unless File.read(gemfile_path).match?(/^\s*gem ['"]redis['"]/)

    # Add gem sidekiq unless already present
    append_to_file(gemfile_path, "\ngem 'sidekiq'\n") unless File.read(gemfile_path).match?(/^\s*gem ['"]sidekiq['"]/)

    # Add gem sidekiq-datadog-error-tracking unless already present
    return if File.read(gemfile_path).match?(/^\s*gem ['"]sidekiq-datadog-error-tracking['"]/)

    append_to_file(gemfile_path, "\ngem 'sidekiq-datadog-error-tracking'\n")
  end

  def add_to_config
    Rails.root.glob('config/environments/*.rb') do |file|
      add_to_config_file(file)
    end
  end

  def add_initializer
    template 'config/initializers/sidekiq.rb'
  end

  def add_routes
    routes_path = Rails.root.join('config/routes.rb')
    return if File.read(routes_path).match?(%r{require ['"]sidekiq/web["']})

    authentication_type = Modulorails.data.authentication_type
    if respond_to?("add_#{authentication_type}_authenticated_route")
      send("add_#{authentication_type}_authenticated_route", routes_path)
    else
      add_unauthenticated_route(routes_path)
    end
  end

  def add_health_check
    file_path = Rails.root.join('config/initializers/health_check.rb')
    return unless File.exist?(file_path)

    return if File.read(file_path).match?(/add_custom_check\s*\(?\s*['"]sidekiq-queues['"]\s*\)?/)

    inject_into_file file_path, after: /^HealthCheck.setup do \|config\|\n$/ do
      <<-RUBY

  # Add one or more custom checks that return a blank string if ok, or an error message if there is an error
  config.add_custom_check('sidekiq-queues') do
    queues = Sidekiq::Queue.all

    # No queues, means no jobs, ok!
    next '' if queues.empty?

    global_latency = queues.each.map { |queue| queue.latency }.sum

    # Global latency is less than 5 minutes, ok!
    global_latency < 5.minutes ? '' : "Global latency (\#{global_latency}) is too high."
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

  def remove_entrypoint
    remove_file 'entrypoints/sidekiq-entrypoint.sh'
    remove_file 'bin/sidekiq-entrypoint'
  end

  private

  def add_to_docker_compose_yml_file(file_path)
    @image_name ||= Modulorails.data.name.parameterize

    unless File.exist?(file_path)
      puts("Compose file not found at #{file_path}. Ignoring.")
      return
    end

    # Update existing Sidekiq service
    if File.read(file_path).match?(/^ {2}sidekiq:$/)
      pattern = /^(\s*)entrypoint:(\s*).\/(bin\/sidekiq-entrypoint|entrypoints\/sidekiq-entrypoint\.sh)/
      gsub_file file_path, pattern, '\1command:\2./bin/bundle exec sidekiq'
      return
    end

    add_sidekiq_service(file_path)
  end

  def add_sidekiq_service(file_path)
    insert_into_file file_path, after: /^services:/ do
      # Using `<<-` Heredoc syntax to preserve YAML indentation
      <<-YAML

  sidekiq:
    image: modulotechgroup/#{@image_name}:dev
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    depends_on:
      - database
      - redis
    volumes:
      - ..:/rails
    environment:
      RAILS_ENV: development
      URL: http://app:3000
    env_file:
      - path: .env
        required: false
    command: ./bin/bundle exec sidekiq
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
    # Do nothing if file does not exist or Sidekiq is already enabled
    return unless File.exist?(file_path)
    return if File.read(file_path).match?(/^sidekiq:\n {2}enabled: true$/m)

    # Add sidekiq to deploy file
    insert_into_file file_path do
      <<~YAML

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
            minReplicas: #{file_path.to_s.match?('production.y') ? 2 : 1}
            maxReplicas: #{file_path.to_s.match?('production.y') ? 10 : 2}
            targetCPUUtilizationPercentage: 80
          command: ["./bin/bundle", "exec", "sidekiq"]
      YAML
    end
  end

  RAILS_AUTHENTICATION_TEMPLATE = <<~RUBY.freeze
    require 'sidekiq/web'
    constraints lambda { |request| Session.find_by(id: request.cookie_jar.signed[:session_id])&.user&.role == 'admin' } do
      mount Sidekiq::Web => '/admin/sidekiq'
    end


  RUBY

  def add_devise_authenticated_route(routes_path)
    template = <<~RUBY
      require 'sidekiq/web'
      authenticate :user, lambda { |u| u.respond_to?('role') && u.role == 'admin' } do
        mount Sidekiq::Web => '/admin/sidekiq'
      end

    RUBY
    puts("Injecting #{template} into #{routes_path}: update the authentication block.")
    inject_into_file routes_path, template, after: "Rails.application.routes.draw do\n"
  end

  def add_rails_authenticated_route(routes_path)
    template = RAILS_AUTHENTICATION_TEMPLATE
    puts("Injecting #{template} into #{routes_path}: update the authentication block.")
    inject_into_file routes_path, template, after: "Rails.application.routes.draw do\n"
  end

  def add_unauthenticated_route(routes_path)
    template = <<~RUBY
      require 'sidekiq/web'
      mount Sidekiq::Web => '/admin/sidekiq'

    RUBY
    puts("Injecting #{template} into #{routes_path}: you should add authentication to the route.")
    puts("If you do not have authentication, execute `rails generate authentication` and replace \
          the route by #{RAILS_AUTHENTICATION_TEMPLATE}.")
    inject_into_file routes_path, template, after: "Rails.application.routes.draw do\n"
  end

end
