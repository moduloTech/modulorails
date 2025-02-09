# frozen_string_literal: true

require 'modulorails/generators/docker_base'

module Modulorails

  module Docker

    class ComposeGenerator < ::Modulorails::Generators::DockerBase

      VERSION = 2

      desc 'This generator creates Docker Compose configuration'

      protected

      def create_config
        remove_file('docker-compose.yml')
        remove_file('compose.yml')
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate Docker Compose configuration: #{e.message}")
      end

    end

  end

end
