require_relative '../../app/helpers/modulorails/application_helper'

module Modulorails

  # Bind in the Rails lifecycle
  class Railtie < ::Rails::Railtie

    # Update and add gems before we load the configuration
    config.before_configuration do
      # Currently, we limit everything to the development environment
      if Rails.env.development?
        # Check database configuration
        Modulorails.generate_healthcheck_template
      end
    end

    # Require the gem before we read the health_check initializer
    config.before_initialize do
      require 'health_check'
    end

    initializer 'modulorails.action_view' do
      ActiveSupport.on_load :action_view do
        include Modulorails::ApplicationHelper
      end
    end

    initializer 'modulorails.assets' do |app|
      %w[stylesheets javascripts].each do |subdirectory|
        app.config.assets.paths << File.expand_path("../../../app/assets/#{subdirectory}", __FILE__)
      end
    end

    # Sending data after the initialization ensures we can access
    # all gems, constants and configurations we might need.
    config.after_initialize do
      # Currently, we limit everything to the development environment
      if Rails.env.development?
        # Load translations
        I18n.load_path += [File.expand_path('../../config/locales/en.yml', __dir__)]

        # Effectively send the data to the intranet
        Modulorails.send_data

        # Generate a template for CI/CD
        Modulorails.generate_ci_template

        # Check database configuration
        Modulorails.check_database_config

        # Add/update Rubocop config
        Modulorails.generate_rubocop_template

        # Gem's self-update if a new version was released
        Modulorails.self_update
      end
    end

  end

end
