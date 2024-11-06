# frozen_string_literal: true

require 'modulorails/generators/base'
require 'generators/modulorails/docker/entrypoint/entrypoint_generator'
require 'generators/modulorails/docker/dockerfile/dockerfile_generator'
require 'generators/modulorails/docker/compose/compose_generator'
require 'generators/modulorails/docker/config/config_generator'

module Modulorails

  class DockerGenerator < Modulorails::Generators::Base

    VERSION = false

    desc 'This generator creates Docker configuration for an app'

    protected

    def create_config
      remove_old_keepfile('.modulorails-docker')

      # Running first since the Dockerfile generator checks for existence of entrypoint
      Modulorails::Docker::EntrypointGenerator.new([], {}, {}).invoke_all
      Modulorails::Docker::DockerfileGenerator.new([], {}, {}).invoke_all
      Modulorails::Docker::ComposeGenerator.new([], {}, {}).invoke_all
      Modulorails::Docker::ConfigGenerator.new([], {}, {}).invoke_all
    rescue StandardError => e
      warn("[Modulorails] Error: cannot generate Docker configuration: #{e.message}")
    end

  end

end
