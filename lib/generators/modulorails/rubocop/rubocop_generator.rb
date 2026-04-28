# frozen_string_literal: true

require 'modulorails/generators/base'

class Modulorails::RubocopGenerator < Modulorails::Generators::Base

  VERSION = 1

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a configuration for Rubocop'

  protected

  def create_config
    rubocop_config_path = Rails.root.join('.rubocop.yml')
    gitlab_config_path  = Rails.root.join('.gitlab-ci.yml')

    template 'rubocop.yml', rubocop_config_path, force: true

    return unless File.exist?(gitlab_config_path)
    return if File.read(gitlab_config_path).match?(/\s+extends:\s+.lint\s*$/)

    append_file gitlab_config_path do
      <<~YAML

        rubocop:
          extends: .lint
      YAML
    end
  end

end
