RSpec.describe Modulorails do
  # Mock required objects to simulate the dynamic fetchs
  let(:db_connection) do
    instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter, adapter_name: 'test')
  end
  let(:version) do
    instance_double(Gem::Version, version: '1.2.3')
  end
  let(:loaded_specs) do
    {
      'rails'   => instance_double(Bundler::StubSpecification, version: version),
      'bundler' => instance_double(Bundler::StubSpecification, version: version),
      'test'    => instance_double(Bundler::StubSpecification, version: version)
    }
  end
  let(:git_config) { instance_double(Git::Base) }
  let(:git_url) { 'git@github.com:moduloTech/modulorails.git' }
  let(:rails_app) { Test::Application.new }
  let(:bad_request) do
    body = {
      'errors' => ['the main developer can not be found']
    }

    # Can not use HTTParty::Response, since it's way to implement `#[]` seems to be unmockable
    instance_double(Test::MockResponse, body: body, code: 400, success?: false)
  end
  let(:forbidden) { instance_double(Test::MockResponse, body: {}, code: 403, success?: false) }
  let(:success) { instance_double(Test::MockResponse, body: { id: 662 }, code: 200, success?: true) }

  before :each do
    # Mock required methods to simulate the dynamic fetchs
    allow(db_connection).to receive(:select_value).and_return('1.2.3')
    allow(ActiveRecord::Base).to receive(:connection).and_return(db_connection)
    allow(Gem).to receive(:loaded_specs).and_return(loaded_specs)
    allow(Rails).to receive(:root).and_return(Test::RAILS_ROOT)
  end

  after :each do
    # Reset the configuration
    Modulorails.configuration = nil
  end

  describe 'send_data' do
    context 'invalid configuration' do
      it 'raise if there is no endpoint' do
        # Configure the gem
        Modulorails.configure do |config|
          config.name 'name'
          config.main_developer 'dev'
          config.project_manager 'pm'
          config.api_key 'key'
        end

        expect { subject.send_data }.to raise_error(Modulorails::Error, 'No endpoint or api key')
      end

      it 'raise if there is no API key' do
        # Configure the gem
        Modulorails.configure do |config|
          config.name 'name'
          config.main_developer 'dev'
          config.project_manager 'pm'
          config.endpoint 'endpoint'
        end

        expect { subject.send_data }.to raise_error(Modulorails::Error, 'No endpoint or api key')
      end
    end

    context 'valid configuration' do
      before :each do
        # Configure the gem
        Modulorails.configure do |config|
          config.name 'name'
          config.main_developer 'dev'
          config.project_manager 'pm'
          config.endpoint 'endpoint'
          config.api_key 'key'
        end
      end

      it 'silently ignores when the server does not respond' do
        # Mock the call to the webservice and raise a "SocketError" code - no connection to server
        allow(HTTParty).to receive(:post).and_raise(SocketError)

        # Even on endpoint error, the gem does not raise
        expect { subject.send_data }.not_to raise_error

        # The endpoint should have been called
        headers = { 'Content-Type' => 'application/json', 'X-MODULORAILS-TOKEN' => 'key' }
        params  = Modulorails.data.to_params.to_json
        expect(HTTParty).to have_received(:post).with('endpoint', headers: headers, body: params)
      end

      it 'silently ignores when the server responds with a bad request' do
        # Mock the call to the webservice and return a "bad request" code
        allow(HTTParty).to receive(:post).and_return(bad_request)

        # Mock the webservice's response calls
        allow(bad_request).to receive(:[]).with('errors').and_return(bad_request.body['errors'])

        # Even on endpoint error, the gem does not raise
        expect { subject.send_data }.not_to raise_error

        # The endpoint should have been called
        headers = { 'Content-Type' => 'application/json', 'X-MODULORAILS-TOKEN' => 'key' }
        params  = Modulorails.data.to_params.to_json
        expect(HTTParty).to have_received(:post).with('endpoint', headers: headers, body: params)

        # On a bad request, the errors should be displayed
        expect(bad_request).to have_received(:[]).with('errors')
      end

      it 'silently ignores when the server responds with an authentication error' do
        # Mock the call to the webservice and return a "forbidden" code
        allow(HTTParty).to receive(:post).and_return(forbidden)

        # Mock the webservice's response calls
        allow(forbidden).to receive(:[]).with('errors')

        # Even on endpoint error, the gem does not raise
        expect { subject.send_data }.not_to raise_error

        # The endpoint should have been called
        headers = { 'Content-Type' => 'application/json', 'X-MODULORAILS-TOKEN' => 'key' }
        params  = Modulorails.data.to_params.to_json
        expect(HTTParty).to have_received(:post).with('endpoint', headers: headers, body: params)

        # On a forbidden request, the errors should not be displayed (since the server does not)
        # send messages
        expect(forbidden).not_to have_received(:[])
      end

      it 'silently ignores when the server responds with a success code' do
        # Mock the call to the webservice and return a "success" code
        allow(HTTParty).to receive(:post).and_return(success)

        # The gem does not raise
        expect { subject.send_data }.not_to raise_error

        # The endpoint should have been called
        headers = { 'Content-Type' => 'application/json', 'X-MODULORAILS-TOKEN' => 'key' }
        params  = Modulorails.data.to_params.to_json
        expect(HTTParty).to have_received(:post).with('endpoint', headers: headers, body: params)
      end
    end
  end
end
