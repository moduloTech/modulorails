# frozen_string_literal: true

require 'rails/generators'

class Modulorails::GitlabciGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator creates a template for a .gitlab-ci.yml file at root'

  def create_config_file
    @data = Modulorails.data
    @image_name = @data.name.parameterize
    @environment_name = @data.environment_name
    @adapter = data.adapter
    @review_base_url = @data.review_base_url
    @staging_url = @data.staging_url
    @production_url = @data.production_url

    # Update the gitlab-ci template
    template '.gitlab-ci.yml'
    template 'config/deploy/production.yaml' if @production_url.present?
    template 'config/deploy/staging.yaml' if @staging_url.present?
    template 'config/deploy/review.yaml' if @review_base_url.present?

    # Remove the database-ci template if it exists.
    # It used to be referenced by the gitlab-ci template.
    remove_file 'config/database-ci.yml'

    # Create file to avoid this generator on next modulorails launch
    create_keep_file
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate CI configuration: #{e.message}")
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
