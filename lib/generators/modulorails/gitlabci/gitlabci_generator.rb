# frozen_string_literal: true

require 'modulorails/generators/base'

class Modulorails::GitlabciGenerator < Modulorails::Generators::Base

  VERSION = 2

  desc 'This generator creates a template for a .gitlab-ci.yml file at root'

  protected

  def create_config
    remove_old_keepfile('.modulorails-gitlab-ci')
    remove_old_keepfile('.modulorails-gitlabci')

    @data = Modulorails.data
    @image_name = @data.name.parameterize
    @environment_name = @data.environment_name
    @adapter = @data.adapter
    @review_base_url = @data.review_base_url
    @staging_url = @data.staging_url
    @production_url = @data.production_url

    # Update the gitlab-ci template
    template '.gitlab-ci.yml'
    template 'bin/test.sh', 'bin/test'
    template 'config/deploy/production.yaml' if @production_url.present?
    template 'config/deploy/staging.yaml' if @staging_url.present?
    template 'config/deploy/review.yaml' if @review_base_url.present?

    # Remove the database-ci template if it exists.
    # It used to be referenced by the gitlab-ci template.
    remove_file 'config/database-ci.yml'
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate CI configuration: #{e.message}")
  end

end
