# frozen_string_literal: true

require 'modulorails/generators/base'

class Modulorails::HealthCheckGenerator < Modulorails::Generators::Base

  VERSION = 1

  desc 'This generator creates a configuration for the health_check gem'

  protected

  def create_config
    # Update the template
    template 'config/initializers/health_check.rb'

    # Add the route
    return if Rails.root.join('config/routes.rb').read.match?('health_check_routes')

    inject_into_file 'config/routes.rb', "  health_check_routes\n\n", after: "Rails.application.routes.draw do\n"
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate health_check configuration: #{e.message}")
  end

  def keep_file_name
    '.modulorails-health_check'
  end

end
