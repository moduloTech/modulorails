RSpec.describe Modulorails do
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

  describe Modulorails::Data do
    before :each do
      # Configure the gem
      Modulorails.configure do |config|
        config.name 'name'
        config.main_developer 'dev'
        config.project_manager 'pm'
        config.endpoint 'endpoint'
        config.api_key 'key'
        config.production_url 'url'
        config.staging_url 'url'
        config.review_base_url 'url'
      end

      # Mock required methods to simulate the dynamic fetchs
      allow(db_connection).to receive(:select_value).and_return('1.2.3')
      allow(ActiveRecord::Base).to receive(:connection).and_return(db_connection)
      allow(Gem).to receive(:loaded_specs).and_return(loaded_specs)
      allow(Rails).to receive(:root).and_return(Test::RAILS_ROOT)
      allow(git_config).to receive(:config).and_return(git_url)
      allow(Git).to receive(:open).and_return(git_config)
      allow(Rails).to receive(:application).and_return(rails_app)
    end

    it 'name has the correct value' do
      expect(subject.name).to eq('name')
    end

    it 'main_developer has the correct value' do
      expect(subject.main_developer).to eq('dev')
    end

    it 'project_manager has the correct value' do
      expect(subject.project_manager).to eq('pm')
    end

    it 'production_url has the correct value' do
      expect(subject.production_url).to eq('url')
    end

    it 'staging_url has the correct value' do
      expect(subject.staging_url).to eq('url')
    end

    it 'review_base_url has the correct value' do
      expect(subject.review_base_url).to eq('url')
    end

    it 'repository has the correct value' do
      expect(subject.repository).to eq(git_url)
    end

    it 'type has the correct value' do
      expect(subject.type).to eq('rails')
    end

    it 'rails_name has the correct value' do
      expect(subject.rails_name).to eq('Test')
    end

    it 'ruby_version has the correct value' do
      expect(subject.ruby_version).to eq(RUBY_VERSION)
    end

    it 'rails_version has the correct value' do
      expect(subject.rails_version).to eq('1.2.3')
    end

    it 'bundler_version has the correct value' do
      expect(subject.bundler_version).to eq('1.2.3')
    end

    it 'modulorails_version has the correct value' do
      expect(subject.modulorails_version).to eq(Modulorails::VERSION)
    end

    it 'adapter has the correct value' do
      expect(subject.adapter).to eq('test')
    end

    it 'db_version has the correct value' do
      expect(subject.db_version).to eq('1.2.3')
    end

    it 'adapter_version has the correct value' do
      expect(subject.adapter_version).to eq('1.2.3')
    end

    it 'to_params returns the valid hash' do
      h = {
        'name'            => 'name',
        'main_developer'  => 'dev',
        'project_manager' => 'pm',
        'repository'      => git_url,
        'app_type'        => 'rails',
        'project_data'    => {
          'name'                => 'Test',
          'ruby_version'        => RUBY_VERSION,
          'rails_version'       => '1.2.3',
          'bundler_version'     => '1.2.3',
          'modulorails_version' => Modulorails::VERSION,
          'database'            => {
            'adapter'     => 'test',
            'db_version'  => '1.2.3',
            'gem_version' => '1.2.3'
          },
          'urls'                => {
            'production'  => 'url',
            'staging'     => 'url',
            'review_base' => 'url'
          }
        }
      }
      expect(subject.to_params).to eq(h)
    end
  end
end
