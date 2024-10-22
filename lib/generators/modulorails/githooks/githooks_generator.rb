require 'rails/generators/base'

module Modulorails

  class GithooksGenerator < Rails::Generators::Base

    source_root File.expand_path('templates', __dir__)

    def create_refresh_generations_script
      template 'refresh_generations.sh', 'bin/refresh_generations.sh'
      chmod 'bin/refresh_generations.sh', 0o755
    end

    def create_git_hooks
      %w[post-rewrite pre-merge-commit].each do |hook|
        template 'git_hook.sh', ".git/hooks/#{hook}"
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

      create_file file, content, force: true
    end

    def create_keep_file
      file = '.modulorails-githooks'

      # Create file to avoid this generator on next modulorails launch
      create_file file, 'Modulorails::GithooksGenerator', force: true
    end

  end

end
