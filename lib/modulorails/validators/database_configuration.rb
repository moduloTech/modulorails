module Modulorails

  module Validators

    # Author: Matthieu 'ciappa_m' Ciappara
    # This holds the rules to configure the database by respecting Modulotech's norms.
    class DatabaseConfiguration

      def initialize
        # All rules are invalid by default
        @rules = {
          standard_config_file_location:         false,
          test_database_not_equals_dev_database: false,
          development:                           {
            configurable_username: false,
            configurable_password: false,
            configurable_database: false,
            configurable_host:     false,
            configurable_port:     false
          },
          test:                                  {
            configurable_username: false,
            configurable_password: false,
            configurable_database: false,
            configurable_host:     false,
            configurable_port:     false
          }
        }
      end

      def self.call
        new.call
      end

      def call
        database_configuration = check_standard_config_file_location
        return [:standard_config_file_location] unless database_configuration

        check_test_database_not_equals_dev_database(database_configuration)
        check_rules_for_environment(database_configuration, :development)
        check_rules_for_environment(database_configuration, :test)

        fetch_invalid_rules
      end

      private

      def fetch_invalid_rules
        dev     = select_invalid_keys(@rules[:development]).map { |k| "development.#{k}" }
        test    = select_invalid_keys(@rules[:test]).map { |k| "test.#{k}" }
        general = select_invalid_keys(@rules)

        general + dev + test
      end

      def select_invalid_keys(hash)
        hash.select { |_k, v| v == false }.keys
      end

      def check_standard_config_file_location
        # Load the configuration
        config = if Modulorails::COMPARABLE_RUBY_VERSION >= Gem::Version.new('3.1')
                   # Ruby 3.1 uses Psych4 which changes the default way of handling aliases in
                   # `load_file`.
                   Psych.load_file(Rails.root.join('config/database.yml'), aliases: true)
                 else
                   Psych.load_file(Rails.root.join('config/database.yml'))
                 end

        # If no exception was raised, then the database configuration file is at standard location
        @rules[:standard_config_file_location] = true

        config
      rescue StandardError
        # An exception was raised, either the file is not a the standard location, either it just
        # cannot be read. Either way, we consider the config as invalid
        @rules[:standard_config_file_location] = false
        nil
      end

      # The database for tests MUST NOT be the same as the development database since the test
      # database is rewritten each time the tests are launched
      def check_test_database_not_equals_dev_database(config)
        @rules[:test_database_not_equals_dev_database] =
          config['test']['database'] != config['development']['database']
      end

      # Check all rules for an environment
      def check_rules_for_environment(config, env)
        @rules[env].each_key do |rule|
          key = rule.to_s.gsub(/configurable_/, '')
          check_configurable_key_for_environment(config, env, key)
        end
      end

      # Check if the given key is configurable for the given environment
      def check_configurable_key_for_environment(config, env, key)
        valid_rule = config[env.to_s][key] =~ /<%=\s*ENV\.fetch\(\S+,\s*\S+\)\s*%>/
        valid_rule ||= config[env.to_s][key] =~ /<%=\s*ENV\.fetch\(.+\)\s*\{\s*\S+\s*\}\s*%>/

        # Use of `!!` to convert `nil` to `false` and `0` to `true`
        @rules[env][:"configurable_#{key}"] = !!valid_rule
      end

    end

  end

end
