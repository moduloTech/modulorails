# frozen_string_literal: true

require 'rails/generators'

class Modulorails::ModuloprojectGenerator < Modulorails::Generators::Base

  desc 'This generator creates templates for Moduloproject'

  def create_config
    template 'config/environments/production.rb'
    copy_file('config/environments/production.rb', 'config/environments/staging.rb')
    update_application_rb
    create_file('config/locales/fr.yml', "--\nfr: {}\n")
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate Moduloproject configuration: #{e.message}")
  end

  private

  def update_application_rb
    file = 'config/application.rb'
    pattern = /^(?>\s*)(?>#\s*)?config.time_zone = .+$/

    config = <<-RUBY

    config.time_zone = 'Europe/Paris'
    I18n.available_locales = %i[fr en]
    I18n.default_locale = 'fr'

    uri = URI.parse(ENV.fetch('URL', 'http://localhost:3000'))
    config.url = uri
    Rails.application.routes.default_url_options = { protocol: uri.scheme, host: uri.host, port: uri.port }
    RUBY

    if File.read(file).match?(pattern)
      gsub_file(file, pattern, config)
    else
      append_file(file, "\n#{config.chomp}", after: /^(?>\s*)(?>#\s*)?config.load_defaults.+$/)
    end
  end

end
