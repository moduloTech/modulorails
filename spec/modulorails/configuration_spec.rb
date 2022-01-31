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

  before :each do
    # Mock required methods to simulate the dynamic fetchs
    allow(db_connection).to receive(:select_value).and_return('1.2.3')
    allow(ActiveRecord::Base).to receive(:connection).and_return(db_connection)
    allow(Gem).to receive(:loaded_specs).and_return(loaded_specs)
    allow(Rails).to receive(:root).and_return(Test::RAILS_ROOT)
    allow(git_config).to receive(:config).and_return(git_url)
    allow(Git).to receive(:open).and_return(git_config)
    allow(Rails).to receive(:application).and_return(rails_app)
  end

  after :each do
    # Reset the configuration
    Modulorails.configuration = nil
  end

  describe Modulorails::Configuration do
    %i[name main_developer project_manager endpoint api_key production_url
      staging_url review_base_url].each do |field|
      it "#{field} can be read and configured" do
        expect(subject.send(field)).to be_nil
        subject.send(field, 'test')
        expect(subject.send(field)).to eq('test')
      end
    end
  end
end
