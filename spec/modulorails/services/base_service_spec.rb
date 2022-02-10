RSpec.describe Modulorails do
  describe Modulorails::BaseService do
    it 'raises NotImplementedError when using #call' do
      expect { Modulorails::BaseService.call }.to raise_error(NotImplementedError)
      expect { Modulorails::BaseService.new.call }.to raise_error(NotImplementedError)
    end

    it 'returns its classname on to_s and to_tag' do
      expect(subject.to_s).to eq('Modulorails::BaseService')
      expect(subject.to_tag).to eq('Modulorails::BaseService')
    end
  end

  describe Modulorails::LogsForMethodService do
    let(:logger) { instance_double(ActiveSupport::Logger) }
    let(:taggable) { Modulorails::BaseService.new }

    before :each do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(:debug)
    end

    it 'logs message to debug without tags when using #call' do
      Modulorails::LogsForMethodService.call(method: 'method', message: 'message')
      message = '[method] message'

      expect(logger).to have_received(:debug).with(message).at_least(1).times
    end

    it 'logs message to debug with string tags when using #call' do
      Modulorails::LogsForMethodService.call(method: 'method', message: 'message', tags: %w[tag1 tag2])
      message = '[tag1][tag2][method] message'

      expect(logger).to have_received(:debug).with(message).at_least(1).times
    end

    it 'logs message to debug with object tags when using #call' do
      Modulorails::LogsForMethodService.call(method: 'method', message: 'message', tags: ['tag1', taggable])
      message = '[tag1][Modulorails::BaseService][method] message'

      expect(logger).to have_received(:debug).with(message).at_least(1).times
    end

    it 'logs object to debug without tags when using #call' do
      Modulorails::LogsForMethodService.call(method: 'method', message: { object: 'test' })
      message = '[method] {"object":"test"}'

      expect(logger).to have_received(:debug).with(message).at_least(1).times
    end

    it 'logs object to debug with string tags when using #call' do
      Modulorails::LogsForMethodService.call(method: 'method', message: { object: 'test' }, tags: %w[tag1 tag2])
      message = '[tag1][tag2][method] {"object":"test"}'

      expect(logger).to have_received(:debug).with(message).at_least(1).times
    end

    it 'logs object to debug with object tags when using #call' do
      Modulorails::LogsForMethodService.call(method: 'method', message: { object: 'test' }, tags: ['tag1', taggable])
      message = '[tag1][Modulorails::BaseService][method] {"object":"test"}'

      expect(logger).to have_received(:debug).with(message).at_least(1).times
    end
  end
end
