require 'bundler/setup'
require 'modulorails'

# Author: Matthieu 'ciappa_m' Ciappara
# Classes used in specs for mocks
module Test
  # Simulate a Rails application
  # Currently, only an appropriate naming is necessary so no attributes
  class Application; end

  # Simulate needed behaviours from Rails root
  RAILS_ROOT = Pathname.new(File.expand_path('../..', __FILE__))

  # Simulate an HTTParty::Response
  # HTTParty::Response mocking does not work properly. RSpec mocks can not see the method `#[]` on
  # the object thus forbidding the allowance to answer `#[]` with a static return.
  class MockResponse
    def initialize(body:, code:, success:)
      @body = body
      @code = code
      @success = success
    end

    # Those are the methods we need to be able to mock for the current specs
    attr_reader :body, :code, :success

    # For instance, `HTTParty::Response.new(...)['errors']` will look for an 'errors' field in the
    # body
    delegate :[], to: :body

    # @return [Boolean] Was the call a success?
    def success?
      # Using `!!` to ensure a boolean return whatever the nature of the `@success` attribute
      !!@success
    end
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Instruct RSpec to use the newest `expect` syntax instead of the original `should` syntax
  # https://github.com/rspec/rspec-expectations/blob/master/Should.md
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
