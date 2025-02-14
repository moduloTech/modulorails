# frozen_string_literal: true

require 'modulorails/generators/base'

module Modulorails

  class GithooksGenerator < Modulorails::Generators::Base

    VERSION = 1

    protected

    def create_config
      remove_old_keepfile('.modulorails-githooks')
      create_hook_executor
      create_refresh_generations_script
      create_git_hooks
      update_gitattributes
    end

    private

    def create_hook_executor
      template 'dc.sh', 'bin/dc'
      chmod 'bin/dc', 0o755
      template 'dcr.sh', 'bin/dcr'
      chmod 'bin/dcr', 0o755
    end

    def create_refresh_generations_script
      template 'refresh_generations.sh', 'bin/refresh_generations'
      chmod 'bin/refresh_generations', 0o755
    end

    def create_git_hooks
      %w[post-rewrite pre-merge-commit].each do |hook|
        template "#{hook}.sh", ".git/hooks/#{hook}"
        chmod ".git/hooks/#{hook}", 0o755
      end
    end

    def update_gitattributes
      content = <<~CONTENT
        # See https://git-scm.com/docs/gitattributes for more about git attribute files.

        # Mark any vendored files as having been vendored.
        vendor/* linguist-vendored

        config/credentials/*.yml.enc diff=rails_credentials
        config/credentials.yml.enc diff=rails_credentials

        Gemfile.lock merge=ours
        app/assets/javascripts/i18n/translations.js merge=ours
        db/schema.rb merge=ours
      CONTENT

      create_file '.gitattributes', content, force: true
    end

  end

end
