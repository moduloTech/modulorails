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
    # Reset the configuration before each example to prevent leakage from sibling spec files
    # (e.g. data_spec.rb configures Modulorails but does not reset it after).
    Modulorails.configuration = nil

    # Mock required methods to simulate the dynamic fetchs
    allow(db_connection).to receive(:select_value).and_return('1.2.3')
    allow(ActiveRecord::Base).to receive(:connection).and_return(db_connection)
    allow(Gem).to receive(:loaded_specs).and_return(loaded_specs)
    allow(Rails).to receive(:root).and_return(Test::RAILS_ROOT)

    # The minimal Test::Application stub does not set up a logger; provide a real Logger backed
    # by an in-memory StringIO so Rails.logger.debug calls don't blow up the nominal-path specs
    # while still evaluating their blocks. (A null-object double or Logger.new(File::NULL) would
    # skip block evaluation, breaking assertions that depend on side effects inside the block —
    # File::NULL triggers a short-circuit optimization in Ruby's Logger.)
    allow(Rails).to receive(:logger).and_return(Logger.new(StringIO.new))
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

      context 'when data collection fails' do
        # `data.to_params.to_json` used to live outside the begin/rescue, so any failure in
        # Modulorails::Data.new (e.g. a malformed configuration) would propagate out of
        # send_data and crash Rails boot in `after_initialize`. It must now be swallowed.
        before :each do
          allow(Modulorails).to receive(:data).and_raise(StandardError, 'boom')
        end

        it 'does not raise' do
          expect { subject.send_data }.not_to raise_error
        end

        it 'does not attempt the HTTP call' do
          allow(HTTParty).to receive(:post)
          subject.send_data
          expect(HTTParty).not_to have_received(:post)
        end
      end

      context 'when Rails.logger is nil' do
        # Rails is not always booted with a logger (e.g. early initialization, minimal apps).
        # `send_data` must not crash on debug logging in that case.
        before :each do
          allow(Rails).to receive(:logger).and_return(nil)
        end

        it 'does not raise on the rescue path when the server does not respond' do
          allow(HTTParty).to receive(:post).and_raise(SocketError)

          expect { subject.send_data }.not_to raise_error
        end

        it 'does not raise on the bad-request logging path' do
          allow(HTTParty).to receive(:post).and_return(bad_request)
          allow(bad_request).to receive(:[]).with('errors').and_return(bad_request.body['errors'])

          expect { subject.send_data }.not_to raise_error
        end
      end
    end
  end
end
