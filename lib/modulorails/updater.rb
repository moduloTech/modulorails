module Modulorails
  # Author: Matthieu 'ciappa_m' Ciappara
  # This updates modulorails by editing the gemfile and running a bundle update
  class Updater
    LATEST_VERSION_URL = 'https://rubygems.org/api/v1/versions/modulorails/latest.json'.freeze

    def self.call(*args)
      new(*args).call
    end

    def call
      # Get the last published version
      @last_published_version = HTTParty.get(LATEST_VERSION_URL).parsed_response['version']

      # Do nothing if we could not fetch the last published version (whatever the reason)
      # Or if the current version is the same as the last published version
      return if @last_published_version.nil? || @last_published_version == Modulorails::VERSION

      # If the last published version is different from the current version, we update the gem
      edit_gemfile
    end

    private

    def edit_gemfile
      # Log to warn the user
      puts("[Modulorails] Last version for modulorails is #{@last_published_version} while you "\
        "are using version #{Modulorails::VERSION}. Running auto-update.")

      # Read the lines of the Gemfile
      gemfile_location = Rails.root.join('Gemfile')
      lines            = File.readlines gemfile_location

      # Search and replace the modulorails line
      index = lines.index { |l| l =~ /gem\s['"]modulorails['"]/ }
      lines[index].gsub!(/(\s*)gem\s['"]modulorails['"].*/,
                         "#{$1}gem 'modulorails', '= #{@last_published_version}'")

      # Update the Gemfile
      File.open(gemfile_location, 'w') { |f| f.puts(lines) }

      # Update the gem and the Gemfile.lock
      system('bundle install')
    end
  end
end
