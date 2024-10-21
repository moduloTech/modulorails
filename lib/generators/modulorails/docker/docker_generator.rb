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

    template 'Dockerfile'
    template 'Dockerfile.prod'
    template 'compose.yml'
    template 'entrypoints/docker-entrypoint.sh'
    chmod 'entrypoints/docker-entrypoint.sh', 0o755
    template 'config/database.yml'
    template 'config/cable.yml'
    template 'config/initializers/0_redis.rb'
    template 'config/puma.rb'

    # Useless unless project is using Webpacker
    return unless @webpack_container_needed

    template 'entrypoints/webpack-entrypoint.sh'
    chmod 'entrypoints/webpack-entrypoint.sh', 0o755
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate Docker configuration: #{e.message}")
  end

end
