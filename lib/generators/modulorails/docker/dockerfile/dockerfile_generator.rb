# frozen_string_literal: true

require 'modulorails/generators/docker_base'

module Modulorails

  module Docker

    class DockerfileGenerator < ::Modulorails::Generators::DockerBase

      VERSION = 1

      desc 'This generator creates Dockerfiles'

      protected

      def create_config
        @data = Modulorails.data
        @adapter = @data.adapter
        @webpack_container_needed = @data.webpacker_version.present?

        EntrypointGenerator.new([], {}, {}).invoke_all unless File.exist?('bin/docker-entrypoint')
        create_dockerfile
        create_dockerfile_prod
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate Dockerfiles: #{e.message}")
      end

      private

      def create_dockerfile
        template 'dockerfiles/modulotech/Dockerfile', 'Dockerfile'
      end

      def create_dockerfile_prod
        if Gem::Version.new(@data.rails_version) >= Gem::Version.new('7.2')
          template 'dockerfiles/rails/Dockerfile.prod', 'Dockerfile.prod'
        else
          template 'dockerfiles/modulotech/Dockerfile.prod', 'Dockerfile.prod'
        end
      end

    end

  end

end
