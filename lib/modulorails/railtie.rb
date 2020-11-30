module Modulorails
  class Railtie < ::Rails::Railtie
    # Binding in the Rails lifecycle. Sending data after the initialization ensures we can access
    # all gems and symbols we might have to use.
    config.after_initialize do
      # For now, we limit everything to the development environment
      if Rails.env.development?
        # Load translations
        I18n.load_path += [File.expand_path('../../../config/locales/en.yml', __FILE__)]

        # Effectively send the data to the intranet
        Modulorails.send_data

        # Generate a template for CI/CD
        Modulorails.generate_ci_template

        # Check database configuration
        Modulorails.check_database_config

        # Gem's self-update if a new version was released
        Modulorails.self_update
      end
    end
  end
end
