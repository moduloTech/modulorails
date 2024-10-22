# frozen_string_literal: true

require 'rails/generators'

class Modulorails::BundlerauditGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a configuration for Bundler-Audit'

  def create_config_files
    gitlab_config_path = Rails.root.join('.gitlab-ci.yml')

    return if File.read(gitlab_config_path).match?(/\s+extends:\s+.bundleraudit\s*$/)

    append_file gitlab_config_path do
      <<~YAML

        # Scan Gemfile.lock for Common Vulnerabilities and Exposures
        # https://en.wikipedia.org/wiki/Common_Vulnerabilities_and_Exposures
        # https://www.cve.org/
        bundleraudit:
          extends: .bundleraudit
      YAML
    end
  end

end
