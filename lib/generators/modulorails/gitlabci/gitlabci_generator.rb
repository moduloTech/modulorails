# frozen_string_literal: true

require 'rails/generators'

class Modulorails::GitlabciGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a template for a .gitlab-ci.yml file at root'

  def create_config_file
    # Update the gitlab-ci template
    template '.gitlab-ci.yml'

    # Remove the database-ci template if it exists.
    # It used to be referenced by the gitlab-ci template.
    remove_file 'config/database-ci.yml'

    # Create file to avoid this generator on next modulorails launch
    create_keep_file
  rescue StandardError => e
    $stderr.puts("[Modulorails] Error: cannot generate CI configuration: #{e.message}")
  end

  private

  def create_keep_file
    file = '.modulorails-gitlab-ci'

    # Create file to avoid this generator on next modulorails launch
    copy_file(file, file)

    say "Add #{file} to git"
    %x(git add #{file})
  end
end
