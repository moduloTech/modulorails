# frozen_string_literal: true

require 'rails/generators'

# Author: Matthieu 'ciappa_m' Ciappara
# This updates modulorails by editing the gemfile and running a bundle update
class Modulorails::SelfUpdateGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator updates Modulorails if required'

  LATEST_VERSION_URL = 'https://rubygems.org/api/v1/versions/modulorails/latest.json'

  def create_config_file
    modulorails_version = Gem::Version.new(Modulorails::VERSION)

    # Get the last published version
    last_published_version_s = HTTParty.get(LATEST_VERSION_URL).parsed_response['version']
    last_published_version   = Gem::Version.new(last_published_version_s)

    # Do nothing if we could not fetch the last published version (whatever the reason)
    # Or if the current version is the same as the last published version
    return if last_published_version <= modulorails_version

    # Add gem to Gemfile
    gsub_file 'Gemfile', /^\s*gem\s['"]modulorails['"].*$/,
              "gem 'modulorails', '= #{last_published_version}'"

    # Update the gem and the Gemfile.lock
    system('bundle install')
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate health_check configuration: #{e.message}")
  end

end
