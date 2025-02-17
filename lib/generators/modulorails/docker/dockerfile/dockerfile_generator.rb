# frozen_string_literal: true

require 'modulorails/generators/docker_base'

module Modulorails

  module Docker

    class DockerfileGenerator < ::Modulorails::Generators::DockerBase

      VERSION = 2

      desc 'This generator creates Dockerfiles'

      protected

      def create_config
        @data = Modulorails.data
        @adapter = @data.adapter
        @js_engine = @data.js_engine

        EntrypointGenerator.new([], {}, {}).invoke_all unless File.exist?('bin/docker-entrypoint')
        create_dockerfile_prod
        create_dockerignore
      rescue StandardError => e
        warn("[Modulorails] Error: cannot generate Dockerfiles: #{e.message}")
      end

      private

      def create_dockerfile_prod
        @rails_72_and_more = Gem::Version.new(@data.rails_version) >= Gem::Version.new('7.2')

        remove_file 'Dockerfile.prod'
        template 'dockerfiles/Dockerfile.prod', 'Dockerfile', force: true
      end

      def create_dockerignore
        template 'dockerfiles/dockerignore', '.dockerignore'
      end

    end

  end

end
