# frozen_string_literal: true

require 'rails/generators'

class GitlabciGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)
  class_option(:app,
               required: true, type: :string,
               desc:     'Specify the application name.')
  class_option(:database,
               required: true, type: :string,
               desc:     'Specify the database to use (either mysql or postgres).')
  class_option(:bundler,
               required: true, type: :string,
               desc:     'Specify the Bundler version.')
  class_option(:ruby_version,
               required: true, type: :string,
               desc:     'Specify the Ruby version.')
  desc 'This generator creates a template for a .gitlab-ci.yml file at root'

  # Configurations for MySQL/Postgres dockers
  MYSQL_DOCKER_DB = <<~EOS
    # Install a MySQL 5.7 database and configure mandatory environment variables
    # (https://hub.docker.com/_/mysql/)
    services:
      - mysql:5.7
    variables:
      MYSQL_DATABASE: test
      MYSQL_ROOT_PASSWORD: password
  EOS
  POSTGRES_DOCKER_DB = <<~EOS
    # Install a Postgres 11 database and configure mandatory environment variables
    # (https://hub.docker.com/_/postgres/)
    services:
      - postgresql:11
    variables:
      POSTGRES_DB: test
      POSTGRES_PASSWORD: password
  EOS

  def create_config_file
    # Get the configuration for the database engine
    db_conf = database_config(options[:database])

    # Update the gitlab-ci template
    update_gitlab_ci(options, db_conf)

    # Update the database-ci template
    update_database_ci(db_conf)

    # Create file to avoid this generator on next modulorails launch
    create_keep_file
  rescue StandardError => e
    $stderr.puts("[Modulorails] Error: cannot generate CI configuration: #{e.message}")
  end

  private

  def update_gitlab_ci(options, db_conf)
    file   = '.gitlab-ci.yml'
    exists = File.exists?(file)

    # Remove original file if there is one
    remove_file file if exists

    # Copy file
    copy_file file, file

    # Add the correct database docker
    prepend_file file, db_conf[:header]

    # Replace key for CI/CD cache
    gsub_file file, 'CI_CD_CACHE_KEY', "#{options[:app]}-ci_cd"

    # Replace key for bundler version
    gsub_file file, 'BUNDLER_VERSION', options[:bundler]

    # Replace ruby version
    gsub_file file, 'RUBY_VERSION', '2.5.0'

    # Warn the user about file overwrite/creation
    warn_file_update(file, exists)
  end

  def update_database_ci(db_conf)
    file = 'config/database-ci.yml'
    exists = File.exists?(file)

    # Remove original file if there is one
    remove_file file if exists

    # Copy file
    copy_file file, file

    # Replace configuration
    gsub_file file, 'HOST', db_conf[:host]
    gsub_file file, 'ADAPTER', db_conf[:adapter]
    gsub_file file, 'DATABASE', 'test'

    # Warn the user about file overwrite/creation
    warn_file_update(file, exists)
  end

  def database_config(database)
    case database
    when 'mysql', 'mysql2'
      { header: MYSQL_DOCKER_DB, host: 'mysql', adapter: 'mysql2' }
    when 'postgres', 'postgresql'
      { header: POSTGRES_DOCKER_DB, host: 'postgres', adapter: 'postgresql' }
    else
      raise "Unknown database adapter `#{database}`: either mysql or postgres"
    end
  end

  def warn_file_update(file, exists)
    intro = if exists
              "/!\\ Watch out! Your #{file} was overwritten"
            else
              "A new file #{file} was added"
            end

    say "#{intro} by Modulorails. Ensure everything is correct!"
  end

  def create_keep_file
    file = '.modulorails-gitlab-ci'

    # Create file to avoid this generator on next modulorails launch
    copy_file(file, file)

    say "Add #{file} to git"
    %x(git add #{file})
  end
end
