# frozen_string_literal: true

require 'rails/generators'

class Modulorails::ServiceGenerator < Rails::Generators::NamedBase

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a service inheriting Modulorails::BaseService'
  argument :arguments, type: :array, default: [], banner: 'argument argument'

  check_class_collision suffix: 'Service'

  def create_service_files
    template 'service.rb', File.join('app/services', class_path, "#{file_name}_service.rb")
  end

  private

  def file_name
    @file_name ||= remove_possible_suffix(super)
  end

  def remove_possible_suffix(name)
    name.sub(/_?service$/i, '')
  end

end
