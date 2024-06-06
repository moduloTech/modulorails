# frozen_string_literal: true

require 'rails/generators'

class Modulorails::ModuloprojectGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates templates for Moduloproject'

  def create_config_file
    template 'config/environments/production.rb'
    copy_file('config/environments/production.rb', 'config/environments/staging.rb')
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate Moduloproject configuration: #{e.message}")
  end

  private

  def create_keep_file
    file = '.modulorails-gitlab-ci'

    # Create file to avoid this generator on next modulorails launch
    copy_file(file, file)

    say "Add #{file} to git"
    `git add #{file}`
  end

end
