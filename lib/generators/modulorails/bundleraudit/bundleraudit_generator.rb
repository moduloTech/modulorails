# frozen_string_literal: true

require 'modulorails/generators/base'

class Modulorails::BundlerauditGenerator < Modulorails::Generators::Base

  desc 'This generator creates a configuration for Bundler-Audit'

  protected

  def create_config
    append_file @gitlab_config_path do
      <<~YAML

        # Scan Gemfile.lock for Common Vulnerabilities and Exposures
        # https://en.wikipedia.org/wiki/Common_Vulnerabilities_and_Exposures
        # https://www.cve.org/
        bundleraudit:
          extends: .bundleraudit
      YAML
    end
  end

  def keep_file_present?
    @gitlab_config_path = Rails.root.join('.gitlab-ci.yml')

    !@gitlab_config_path.exist? ||
      @gitlab_config_path.read.match?(/\s+extends:\s+.bundleraudit\s*$/)
  end

end
