# frozen_string_literal: true

require 'rails/generators'

class Modulorails::RubocopGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a configuration for Rubocop'

  def create_config_files
    rubocop_config_path = Rails.root.join('.rubocop.yml')

    template "rubocop.yml", rubocop_config_path, force: true
  end
end
