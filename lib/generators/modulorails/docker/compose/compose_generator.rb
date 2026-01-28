# frozen_string_literal: true

require 'modulorails/generators/docker_base'

module Modulorails

  module Docker

    class ComposeGenerator < ::Modulorails::Generators::DockerBase

      VERSION = 1

      desc 'This generator creates Docker Compose configuration'

      protected

      def create_config
        @data = Modulorails.data
        @adapter = @data.adapter
        @webpack_container_needed = @data.webpacker_version.present?
        @image_name = @data.name.parameterize

        create_new_file('docker-compose.yml', 'compose.yml', executable: false)
        create_env_file
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate Docker Compose configuration: #{e.message}")
      end

      def create_env_file
        env_file = Rails.root.join('.env')
        return if File.exist?(env_file)

        template '.env', '.env'
      end

    end

  end

end
