# frozen_string_literal: true

require 'modulorails/generators/docker_base'
require 'generators/modulorails/sidekiq/sidekiq_generator'

module Modulorails

  module Docker

    class DevcontainerGenerator < Modulorails::Generators::DockerBase

      VERSION = 1

      desc 'This generator creates devcontainer configuration'

      protected

      def create_config
        remove_old_dockerfiles
        create_template_files
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate devcontainer configuration: #{e.message}")
      end

      private

      def remove_old_dockerfiles
        remove_file 'compose.yml'
        remove_file 'docker-compose.yml'
      end

      def create_template_files
        @data = Modulorails.data
        @adapter = @data.adapter
        @image_name = @data.name.parameterize
        @js_engine = @data.js_engine

        template 'devcontainer/devcontainer.json', '.devcontainer/devcontainer.json'
        template 'devcontainer/compose.yml', '.devcontainer/compose.yml'
        template 'devcontainer/Dockerfile', '.devcontainer/Dockerfile'
      end

    end

  end

end
