# frozen_string_literal: true

require 'modulorails/generators/docker_base'
require 'generators/modulorails/sidekiq/sidekiq_generator'

module Modulorails

  module Docker

    class EntrypointGenerator < Modulorails::Generators::DockerBase

      VERSION = 2

      desc 'This generator creates Docker entrypoints'

      protected

      def create_config
        Modulorails.deprecator.warn(<<~MESSAGE)
          Modulorails::Docker::EntrypointGenerator is deprecated and will be removed in version 2.0.
          Use Moduloproject 3.0 (available later) to initialize new projects with Docker configuration.
        MESSAGE

        create_docker_entrypoint
        remove_webpack_entrypoint

        if File.exist?('entrypoints/sidekiq-entrypoint.sh') || File.exist?('bin/sidekiq-entrypoint')
          SidekiqGenerator.new([], {}, {}).invoke('remove_entrypoint')
        end
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate Docker entrypoints: #{e.message}")
      end

      private

      def remove_webpack_entrypoint
        remove_file('entrypoints/webpack-entrypoint.sh')
        remove_file('bin/webpack-entrypoint')
      end

      def create_docker_entrypoint
        create_new_file 'entrypoints/docker-entrypoint.sh', 'bin/docker-entrypoint'
      end

    end

  end

end
