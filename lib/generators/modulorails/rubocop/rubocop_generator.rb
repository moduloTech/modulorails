# frozen_string_literal: true

require 'rails/generators'

class Modulorails::RubocopGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a configuration for Rubocop'

  def create_config_files
    rubocop_config_path = Rails.root.join('.rubocop.yml')
    gitlab_config_path  = Rails.root.join('.gitlab-ci.yml')

    template 'rubocop.yml', rubocop_config_path, force: true

    return if File.read(gitlab_config_path).match?(/\s+extends:\s+.lint\s*$/)

    append_file gitlab_config_path do
      <<~YAML
        rubocop:
          extends: .lint
      YAML
    end
  end

end
