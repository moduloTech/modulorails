# frozen_string_literal: true

require 'modulorails/generators/base'

module Modulorails

  module Generators

    class DockerBase < Modulorails::Generators::Base

      def self.default_generator_root
        File.expand_path("modulorails/docker/#{generator_name}", base_root)
      end

    end

  end

end
