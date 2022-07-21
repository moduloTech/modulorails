# frozen_string_literal: true

require 'rails/generators'

class Modulorails::HealthCheckGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a configuration for the health_check gem'

  def create_config_file
    # Update the template
    template 'config/initializers/health_check.rb'

    # Add the route
    unless File.read(Rails.root.join('config/routes.rb')).match?('health_check_routes')
      inject_into_file 'config/routes.rb', after: "Rails.application.routes.draw do\n" do
        <<~'RUBY'
          health_check_routes
        RUBY
      end
    end

    # Update the gem and the Gemfile.lock
    system('bundle install')

    # Create file to avoid this generator on next modulorails launch
    create_keep_file
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate health_check configuration: #{e.message}")
  end

  private

  def create_keep_file
    file = '.modulorails-health_check'

    # Create file to avoid this generator on next modulorails launch
    copy_file(file, file)

    say "Add #{file} to git"
    `git add #{file}`
  end

end
