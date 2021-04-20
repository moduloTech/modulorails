# frozen_string_literal: true

require 'rails/generators'

class GitlabciGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)
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
    # Update the gitlab-ci template
    template '.gitlab-ci.yml'

    # Update the database-ci template
    template 'config/database-ci.yml'

    # Create file to avoid this generator on next modulorails launch
    create_keep_file
  rescue StandardError => e
    $stderr.puts("[Modulorails] Error: cannot generate CI configuration: #{e.message}")
  end

  private

  def create_keep_file
    file = '.modulorails-gitlab-ci'

    # Create file to avoid this generator on next modulorails launch
    copy_file(file, file)

    say "Add #{file} to git"
    %x(git add #{file})
  end
end
