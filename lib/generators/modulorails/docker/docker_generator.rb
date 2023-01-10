# frozen_string_literal: true

require 'rails/generators'

class Modulorails::DockerGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates Dockerfiles for an app'

  def create_config_file
    template 'Dockerfile'
    template 'Dockerfile.prod'
    template 'docker-compose.yml'
    template 'docker-compose.prod.yml'
    template 'entrypoints/docker-entrypoint.sh'
    chmod 'entrypoints/docker-entrypoint.sh', 0755
    template 'config/database.yml'
    template 'config/cable.yml'

    # Useless unless project is using Webpacker
    if Modulorails.data.webpacker_version.present?
      template 'entrypoints/webpack-entrypoint.sh'
      chmod 'entrypoints/webpack-entrypoint.sh', 0755
    end
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate Docker configuration: #{e.message}")
  end

end
