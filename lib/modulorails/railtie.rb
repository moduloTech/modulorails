module Modulorails
  class Railtie < ::Rails::Railtie
    # Binding in the Rails lifecycle. Sending data after the initialization ensures we can access
    # all gems and symbols we might have to use.
    config.after_initialize do
      # Effectively send the data to the intranet
      Modulorails.send_data
    end
  end
end
