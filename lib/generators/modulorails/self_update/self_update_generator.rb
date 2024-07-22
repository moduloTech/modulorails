# frozen_string_literal: true

require 'rails/generators'

# Author: Matthieu 'ciappa_m' Ciappara
# This updates modulorails by editing the gemfile and running a bundle update
class Modulorails::SelfUpdateGenerator < Rails::Generators::Base

  source_root File.expand_path('templates', __dir__)
  desc 'This generator updates Modulorails if required'

  LATEST_VERSION_URL = 'https://rubygems.org/api/v1/versions/modulorails.json'

  def create_config_file
    # Get the last published version
    last_published_version = HTTParty.get(LATEST_VERSION_URL).parsed_response.first

    # Do nothing if we could not fetch the last published version (whatever the reason)
    return if last_published_version.nil?

    requirement = last_published_version['ruby_version']
    unless ruby_version_supported_by_next_gem_version?(requirement)
      warn("Next Modulorails version requires Ruby version #{requirement}. You should update.")
      return
    end

    modulorails_version = Gem::Version.new(Modulorails::VERSION)

    # Do nothing if the current version is the same as the last published version
    version = Gem::Version.new(last_published_version['number'])
    return if version <= modulorails_version

    # Add gem to Gemfile
    gsub_file 'Gemfile', /^\s*gem\s['"]modulorails['"].*$/,
              "gem 'modulorails', '= #{version}'"

    # Update the gem and the Gemfile.lock
    system('bundle install')
  rescue StandardError => e
    warn("[Modulorails] Error: cannot generate health_check configuration: #{e.message}")
  end

  private

  def ruby_version_supported_by_next_gem_version?(requirement_string)
    requirement = Gem::Requirement.new(requirement_string).requirements.first
    comparison_method, required_version = requirement

    Modulorails::COMPARABLE_RUBY_VERSION.send(comparison_method, required_version)
  rescue StandardError => e
    warn("[ruby_version_supported_by_next_gem_version?] An error occured: #{e.message}")

    # If we cannot be sure of Ruby compatibility, do nothing
    false
  end

end
