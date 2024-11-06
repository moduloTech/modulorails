# frozen_string_literal: true

require 'modulorails/generators/docker_base'
require 'generators/modulorails/sidekiq/sidekiq_generator'

module Modulorails

  module Docker

    class EntrypointGenerator < Modulorails::Generators::DockerBase

      VERSION = 1

      desc 'This generator creates Docker entrypoints'

      protected

      def create_config
        create_docker_entrypoint
        create_webpack_entrypoint if Modulorails.data.webpacker_version.present?

        if File.exist?('entrypoints/sidekiq-entrypoint.sh') || File.exist?('bin/sidekiq-entrypoint')
          SidekiqGenerator.new([], {}, {}).invoke('add_entrypoint')
        end
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate Docker entrypoints: #{e.message}")
      end

      private

      def create_webpack_entrypoint
        create_new_file('entrypoints/webpack-entrypoint.sh', 'bin/webpack-entrypoint')
      end

      def create_docker_entrypoint
        create_new_file 'entrypoints/docker-entrypoint.sh', 'bin/docker-entrypoint'
      end

    end

  end

end
