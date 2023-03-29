# frozen_string_literal: true

require 'rails/generators'

class Modulorails::DockerGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates Dockerfiles for an app'

  def create_config_file
    @data = Modulorails.data
    @adapter = data.adapter
    @webpack_container_needed = data.webpacker_version.present?
    @image_name = @data.name.parameterize
    @environment_name = @data.environment_name

    template 'Dockerfile'
    template 'Dockerfile.prod'
    template 'docker-compose.yml'
    template 'docker-compose.prod.yml'
    template 'entrypoints/docker-entrypoint.sh'
    chmod 'entrypoints/docker-entrypoint.sh', 0755
    template 'config/database.yml'
    template 'config/cable.yml'

    # Useless unless project is using Webpacker
    if @webpack_container_needed
      template 'entrypoints/webpack-entrypoint.sh'
      chmod 'entrypoints/webpack-entrypoint.sh', 0755
    end
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate Docker configuration: #{e.message}")
  end

end
