RSpec.describe Modulorails do
  describe Modulorails::Validators::DatabaseConfiguration do
    let(:valid_config) {
      {
        "development" => {
          "host"     => "<%= ENV.fetch('MYSQL_HOST', 'localhost') %>",
          "port"     => "<%= ENV.fetch('MYSQL_PORT', '3306') %>",
          "adapter"  => "mysql2",
          "encoding" => "utf8",
          "pool"     => "<%= ENV.fetch(\"RAILS_MAX_THREADS\") { 5 } %>",
          "username" => "<%= ENV.fetch('MYSQL_USER', 'root') %>",
          "password" => "<%= ENV.fetch('MYSQL_PASSWORD', '') %>",
          "database" => "<%= ENV.fetch('MYSQL_DB_DEV', 'development_db') %>"
        },
        "test"        => {
          "host"     => "<%= ENV.fetch('MYSQL_HOST', 'localhost') %>",
          "port"     => "<%= ENV.fetch('MYSQL_PORT', '3306') %>",
          "adapter"  => "mysql2",
          "encoding" => "utf8",
          "pool"     => "<%= ENV.fetch(\"RAILS_MAX_THREADS\") { 5 } %>",
          "username" => "<%= ENV.fetch('MYSQL_USER', 'root') %>",
          "password" => "<%= ENV.fetch('MYSQL_PASSWORD', '') %>",
          "database" => "<%= ENV.fetch('MYSQL_DB_DEV', 'test_db') %>"
        }
      }
    }
    let(:invalid_config) {
      {
        "development" => {
          "adapter"  => "mysql2",
          "encoding" => "utf8",
          "pool"     => "<%= ENV.fetch(\"RAILS_MAX_THREADS\") { 5 } %>",
          "username" => "<%= ENV.fetch('MYSQL_USER', 'root') %>",
          "password" => "<%= ENV.fetch('MYSQL_PASSWORD', '') %>",
          "database" => "<%= ENV.fetch('MYSQL_DB_DEV', 'development_db') %>"
        },
        "test"        => {
          "adapter"  => "mysql2",
          "encoding" => "utf8",
          "pool"     => "<%= ENV.fetch(\"RAILS_MAX_THREADS\") { 5 } %>",
          "username" => "<%= ENV.fetch('MYSQL_USER', 'root') %>",
          "password" => "<%= ENV.fetch('MYSQL_PASSWORD', '') %>",
          "database" => "<%= ENV.fetch('MYSQL_DB_DEV', 'test_db') %>"
        }
      }
    }
    let(:invalid_config_result) {
      %w[
        development.configurable_host development.configurable_port
        test.configurable_host test.configurable_port
      ]
    }

    before :each do
      allow(Rails).to receive(:root).and_return(Test::RAILS_ROOT)
    end

    it 'should return [:standard_config_file_location] when the database config file can not be loaded' do
      # Raise ENOENT when file can not be found
      allow(Psych).to receive(:load_file).and_raise(Errno::ENOENT)

      result = nil
      # No exception raised and `false` returned
      expect { result = subject.call }.not_to(raise_error)
      expect(result).to eq([:standard_config_file_location])
    end

    it 'should return an empty array when the database config file is valid' do
      # Return a config
      allow(Psych).to receive(:load_file).and_return(valid_config)

      result = nil
      # No exception raised and an empty array (aka no errors) returned
      expect { result = subject.call }.not_to(raise_error)
      expect(result).to eq([])
    end

    it 'should return an array with the error keys when the database config file is invalid' do
      # Return a config
      allow(Psych).to receive(:load_file).and_return(invalid_config)

      result = nil
      # No exception raised and an empty array (aka no errors) returned
      expect { result = subject.call }.not_to(raise_error)
      expect(result).to eq(invalid_config_result)
    end
  end
end
