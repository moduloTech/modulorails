# frozen_string_literal: true

require 'modulorails/generators/docker_base'

module Modulorails

  module Docker

    class ConfigGenerator < Modulorails::Generators::DockerBase

      VERSION = 2

      desc 'This generator creates application configuration'

      protected

      def create_config
        Modulorails.deprecator.warn(<<~MESSAGE)
          Modulorails::Docker::ConfigGenerator is deprecated and will be removed in version 2.0.
          Use Moduloproject 3.0 (available later) to initialize new projects with Docker configuration.
        MESSAGE

        @data = Modulorails.data
        @adapter = @data.adapter
        @image_name = @data.name.parameterize

        template 'config/database.yml', force: true
        template 'config/cable.yml', force: true
        template 'config/initializers/0_redis.rb', force: true
        template 'config/puma.rb', force: true
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate application configuration: #{e.message}")
      end

    end

  end

end
