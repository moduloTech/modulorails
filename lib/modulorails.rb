require 'modulorails/version'
require 'modulorails/configuration'
require 'modulorails/data'
require 'modulorails/railtie' if defined?(Rails::Railtie)
require 'generators/modulorails/docker/docker_generator'
require 'generators/modulorails/gitlabci/gitlabci_generator'
require 'generators/modulorails/healthcheck/health_check_generator'
require 'generators/modulorails/self_update/self_update_generator'
require 'generators/modulorails/rubocop/rubocop_generator'
require 'generators/modulorails/bundleraudit/bundleraudit_generator'
require 'httparty'
require 'modulorails/error_data'
require 'modulorails/success_data'
require 'modulorails/errors/errors'
require 'modulorails/services/services'

# Author: Matthieu 'ciappa_m' Ciappara
# The entry point of the gem. It exposes the configurator, the gathered data and the method to
# send those data to the intranet.
module Modulorails

  # Author: Matthieu 'ciappa_m' Ciappara
  # The error class of the gem. Allow to identify all functional errors raised by the gem.
  class Error < StandardError; end

  class << self

    # Useful to update the configuration
    attr_writer :configuration

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # When a block is given, it allows to define or update the current configuration. Without a
    # block, this methods is just a configuration getter.
    #
    # @yield [configuration] Block with the current configuration; optional
    # @yieldparam [Modulorails::Configuration] The current configuration
    # @return [Modulorails::Configuration] The current configuration; updated if a block was given
    def configure
      # Get the current configuration if no block is given
      return configuration unless block_given?

      # Pass the configuration to the block and let the block do what it wants (probably update the
      # configuration)
      yield configuration

      # Return the (probably updated) current configuration
      configuration
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # A configuration getter.
    #
    # @return [Modulorails::Configuration] The current configuration
    def configuration
      @configuration ||= Modulorails::Configuration.new
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # A data getter.
    #
    # @return [Modulorails::Data] The current data
    def data
      @data ||= Modulorails::Data.new
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Send the `#data` to the Intranet as JSON. HTTParty is used to send the POST request.
    #
    # @return [HTTParty::Response] The response of the intranet
    # @raise [Modulorails::Error] If the endpoint or the API key of the intranet were not configured
    def send_data
      # If no endpoint and/or no API key is configured, it is impossible to send the data to the
      # intranet and thus we raise an error: it is the only error we want to raise since it goes
      # against one of the main goals of the gem and the gem's user is responsible.
      unless configuration.endpoint && configuration.api_key
        raise Error.new('No endpoint or api key')
      end

      # Define the headers of the request ; sending JSON and API key to authenticate the gem on
      # the intranet
      headers = {
        'Content-Type' => 'application/json', 'X-MODULORAILS-TOKEN' => configuration.api_key
      }

      # Define the JSON body of the request
      body = data.to_params.to_json

      # Prevent HTTParty to raise error and crash the server in dev
      begin
        # Post to the configured endpoint on the Intranet
        response = HTTParty.post(configuration.endpoint, headers: headers, body: body)

        # According to the API specification, on a "Bad request" response, the server explicits what
        # went wrong with an `errors` field. We do not want to raise since the gem's user is not
        # (necessarily) responsible for the error but we still need to display it somewhere to warn
        # the user something went wrong.
        puts("[Modulorails] Error: #{response['errors'].join(', ')}") if response.code == 400

        # Return the response to allow users to do some more
        response
      rescue StandardError => e
        # Still need to notify the user
        puts("[Modulorails] Error: Could not post to #{configuration.endpoint}")
        puts e.message
        nil
      end
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Generate a Docker config template unless it was already done.
    # The check is done using a 'keepfile'.
    def generate_docker_template
      pathname = Rails.root.join('.modulorails-docker')

      if pathname.exist? && pathname.readlines('.modulorails-docker').first
                                    .match(/version: (\d+)/i)&.send(:[], 1).to_i >= DockerGenerator::VERSION
        return
      end

      Modulorails::DockerGenerator.new([], {}, {}).invoke_all
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Generate a CI/CD template unless it was already done.
    # The check is done using a 'keepfile'.
    def generate_ci_template
      return if File.exist?(Rails.root.join('.modulorails-gitlab-ci'))

      Modulorails::GitlabciGenerator.new([], {}, {}).invoke_all
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Check the last version of Modulorails available on rubygems and update if there was a
    # publication
    def self_update
      return if configuration.no_auto_update

      Modulorails::SelfUpdateGenerator.new([], {}, {}).invoke_all
    rescue StandardError => e
      puts("[Modulorails] An error occured: #{e.class} - #{e.message}")
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Generate a health_check configuration unless it was already done.
    # The check is done using a 'keepfile'.
    def generate_healthcheck_template
      return if File.exist?(Rails.root.join('.modulorails-health_check'))

      Modulorails::HealthCheckGenerator.new([], {}, {}).invoke_all
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Generate a rubocop configuration.
    def generate_rubocop_template
      Modulorails::RubocopGenerator.new([], {}, {}).invoke_all
    end

    # @author Matthieu 'ciappa_m' Ciappara
    #
    # Generate a bundler-audit configuration.
    def generate_bundleraudit_template
      Modulorails::BundlerauditGenerator.new([], {}, {}).invoke_all
    end

  end

end
