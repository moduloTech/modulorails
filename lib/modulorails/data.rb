require 'rails'
require 'active_record'
require 'git'

module Modulorails

  # Author: Matthieu 'ciappa_m' Ciappara
  # This holds the data gathered by the gem. Some come from the configuration by the gem's user.
  # Some are fetched dynamically.
  class Data

    # All the data handled by this class
    ATTRIBUTE_KEYS = %i[
      name main_developer project_manager repository type rails_name ruby_version rails_version
      bundler_version modulorails_version adapter db_version adapter_version webpacker_version
      importmap_version jsbundling_version
      production_url staging_url review_base_url
      environment_name
    ].freeze

    # Useful if the gem's user need to read one of the data
    attr_reader(*ATTRIBUTE_KEYS)

    def initialize
      initialize_from_constants
      initialize_from_configuration
      initialize_from_database
      initialize_from_gem_specs
      initialize_from_git
    end

    # @author Matthieu 'ciappa_m' Ciappara
    # @return [String] Text version of the data
    def to_s
      ATTRIBUTE_KEYS.map { |key| "#{key}: #{send(key)}" }.join(', ')
    end

    # @author Matthieu 'ciappa_m' Ciappara
    # @return [Hash] The payload for the request to the intranet
    def to_params
      {
        'name'            => @name,
        'main_developer'  => @main_developer,
        'project_manager' => @project_manager,
        'repository'      => @repository,
        'app_type'        => @type,
        'project_data'    => to_project_data_params
      }
    end

    private

    def initialize_from_constants
      # The API can handle more project types but this gem is (obviously) intended for Rails
      # projects only
      @type = 'rails'

      # The name defined for the Rails application; it can be completely different from the usual
      # name or can be the same
      @rails_name = ::Rails.application.class.name&.split('::')&.first

      # The Ruby version used by the application
      @ruby_version = RUBY_VERSION

      # The version of the gem
      @modulorails_version = Modulorails::VERSION
    end

    def initialize_from_configuration
      # Get the gem's configuration to get the application's usual name, main dev and PM
      configuration = Modulorails.configuration

      # The data written by the user in the configuration
      # The name is the usual name of the project, the one used in conversations at Modulotech
      @name = configuration.name

      # A version of the name suitable to name environment variables
      @environment_name = @name.parameterize.gsub('-', '_').gsub(/\b(\d)/, 'MT_\1').upcase

      # The main developer, the lead developer, in short the developer to call when something's
      # wrong with the application ;)
      @main_developer = configuration.main_developer

      # The project manager of the application; the other person to call when something's wrong with
      # the application ;)
      @project_manager = configuration.project_manager

      # The URL of the production environment for the application
      @production_url = configuration.production_url

      # The URL of the staging environment for the application
      @staging_url = configuration.staging_url

      # The base URL of the review environment for the application.
      # A real review URL is built like this at Modulotech:
      # https://review-#{shortened_branch_name}-#{ci_slug}.#{review_base_url}
      # Example:
      # review_base_url: dev.app.com
      # branch_name: 786-a_super_branch => shortened_branch_name: 786-a_sup
      # ci_slug: jzzham
      # |-> https://review-786-a_sup-jzzham.dev.app.com/
      @review_base_url = configuration.review_base_url
    end

    def initialize_from_database
      # Get the database connection to identify the database used by the application
      # or return nil if the database does not exist
      db_connection = begin
        ActiveRecord::Base.connection
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished => e
        warn("[Modulorails] Error: #{e.message}")
        nil
      end

      # The name of the ActiveRecord adapter; it gives the name of the database system too
      @adapter = db_connection&.adapter_name&.downcase

      # The version of the database engine; this request works only on MySQL and PostgreSQL
      # It should not be a problem since those are the sole database engines used at Modulotech
      @db_version = db_connection&.select_value('SELECT version()')
    end

    def initialize_from_gem_specs
      # Get the gem's specifications to fetch the versions of critical gems
      loaded_specs = Gem.loaded_specs

      # The Rails version used by the application
      @rails_version = gem_version(loaded_specs['rails'])

      # The bundler version used by the application (especially useful since Bundler 2 and
      # Bundler 1 are not compatible)
      @bundler_version = gem_version(loaded_specs['bundler'])

      # The version of the ActiveRecord adapter
      @adapter_version = gem_version(loaded_specs[@adapter])

      # The version of the webpacker gem - might be nil
      @webpacker_version = gem_version(loaded_specs['webpacker'])

      # The version of the importmap-rails gem - might be nil
      @importmap_version = gem_version(loaded_specs['importmap-rails'])

      # The version of the jsbundling-rails gem - might be nil
      @jsbundling_version = gem_version(loaded_specs['jsbundling-rails'])
    end

    def gem_version(spec)
      spec&.version&.version
    end

    def initialize_from_git
      # Theorically, origin is the main repository of the project and git is the sole VCS we use
      # at Modulotech
      @repository = Git.open(::Rails.root).config('remote.origin.url')
    end

    def to_project_data_params
      {
        'name'                => @rails_name,
        'ruby_version'        => @ruby_version,
        'rails_version'       => @rails_version,
        'bundler_version'     => @bundler_version,
        'modulorails_version' => @modulorails_version,
        'database'            => to_database_params,
        'urls'                => to_urls_params
      }
    end

    def to_database_params
      {
        'adapter'     => @adapter,
        'db_version'  => @db_version,
        'gem_version' => @adapter_version
      }
    end

    def to_urls_params
      {
        'production'  => @production_url,
        'staging'     => @staging_url,
        'review_base' => @review_base_url
      }
    end

  end

end
