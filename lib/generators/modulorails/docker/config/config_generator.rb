# frozen_string_literal: true

require 'modulorails/generators/docker_base'

module Modulorails

  module Docker

    class ConfigGenerator < Modulorails::Generators::DockerBase

      VERSION = 1

      desc 'This generator creates application configuration'

      protected

      def create_config
        @data = Modulorails.data
        @adapter = @data.adapter

        template 'config/database.yml'
        template 'config/cable.yml'
        template 'config/initializers/0_redis.rb'
        template 'config/puma.rb'
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate application configuration: #{e.message}")
      end

    end

  end

end
