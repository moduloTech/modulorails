# frozen_string_literal: true

require 'modulorails/generators/docker_base'
require 'generators/modulorails/sidekiq/sidekiq_generator'

module Modulorails

  module Docker

    class DevcontainerGenerator < Modulorails::Generators::DockerBase

      VERSION = 2

      desc 'This generator creates devcontainer configuration with Traefik integration'

      protected

      def create_config
        remove_old_dockerfiles
        create_template_files
        create_env_file
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

      def create_env_file
        env_file_path = '.devcontainer/.env'

        # Only create if the file doesn't exist
        return if File.exist?(Rails.root.join(env_file_path))

        create_file env_file_path, "COMPOSE_PROJECT_NAME=#{@image_name}\n"
      end

    end

  end

end
