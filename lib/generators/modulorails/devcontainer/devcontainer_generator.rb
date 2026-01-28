# frozen_string_literal: true

require 'modulorails/generators/base'

module Modulorails

  class DevcontainerGenerator < Modulorails::Generators::Base

    VERSION = 1

    desc 'This generator creates devcontainer configuration with Traefik support'

    protected

    def create_config
      @data = Modulorails.data
      @adapter = @data.adapter
      @image_name = @data.name.parameterize
      @project_name = @data.name.parameterize
      @webpack_container_needed = @data.webpacker_version.present?
      @ruby_version = @data.ruby_version
      @rails_version = @data.rails_version

      create_new_file('.devcontainer/compose.yml', '.devcontainer/compose.yml', executable: false)
      create_new_file('.devcontainer/devcontainer.json', '.devcontainer/devcontainer.json', executable: false)
    rescue StandardError => e
      warn("[Modulorails] Error: cannot generate devcontainer configuration: #{e.message}")
    end

  end

end
