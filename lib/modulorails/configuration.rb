module Modulorails
  # Author: Matthieu 'ciappa_m' Ciappara
  # The configuration of the gem
  class Configuration
    # All the keys to configure the gem
    attr_accessor :_name, :_main_developer, :_project_manager, :_endpoint, :_api_key,
                  :_no_auto_update, :_production_url, :_staging_url, :_review_base_url

    # This allows to define a DSL to configure the gem
    # Example:
    # Modulorails.configure do |config|
    #   config.name 'MySuperApp'
    #   config.main_developer 'dev@modulotech.fr'
    #   config.project_manager 'pm@modulotech.fr'
    #   config.endpoint "intranet's endpoint"
    #   config.api_key "intranet's api key"
    #   config.production_url "production.app.com"
    #   config.staging_url "staging.app.com"
    #   config.review_base_url "review.app.com"
    # end
    %i[
      name main_developer project_manager endpoint api_key no_auto_update production_url staging_url
      review_base_url
    ].each do |field|
      define_method(field) do |value=nil|
        # No value means we want to get the field
        return send("_#{field}") unless value

        # Else we want to set the field
        send("_#{field}=", value)
      end
    end
  end
end
