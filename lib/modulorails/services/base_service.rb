# @author Matthieu CIAPPARA <ciappa_m@modulotech.fr>
# The base class for services. Should be implemented by ApplicationService following the model of
# ActiveRecord::Base and ApplicationRecord.
class Modulorails::BaseService

  # Allow to instantiate the service and call the service in one go.
  if Modulorails::COMPARABLE_RUBY_VERSION < Gem::Version.new('3.0')
    def self.call(*args, &block)
      new(*args, &block).call
    end
  else
    def self.call(*args, **kwargs, &block)
      new(*args, **kwargs, &block).call
    end
  end

  # @abstract The main method to implement for your service to do something
  def call
    raise NotImplementedError.new('Implement method call on sub-class')
  end

  def to_s
    self.class.to_s
  end

  # The method used by Modulorails::LogsForMethodService to log the service name
  def to_tag
    self.class.to_s
  end

  # Shamelessly copied from text_helper
  def self.pluralize(count, singular, plural_arg=nil, plural: plural_arg, locale: I18n.locale)
    word = if count == 1 || count =~ /^1(\.0+)?$/
             singular
           else
             plural || singular.pluralize(locale)
           end

    "#{count || 0} #{word}"
  end

  protected

  # Wrapper to Modulorails::LogsForMethodService
  # @param method [#to_s] The method calling `#log`
  # @param message [Hash,#to_s] The message to log; Hash will be logged after a #to_json call
  def log(method, message)
    Modulorails::LogsForMethodService.call(method: method, message: message, tags: [self])
  end

  # @param data [Object] The data to pass to the block
  # @yield Wrap the given block in an ActiveRecord transaction.
  # @yieldreturn [Object] Will be available as data of the `SuccessData` returned by the method
  # @return [SuccessData] If the transaction was not rollbacked; give access to the block's return.
  # @return [ErrorData] If the transaction was rollbacked; give access to the rollbacking exception.
  def with_transaction(data: nil)
    data = ActiveRecord::Base.transaction do
      yield(data)
    end

    ::Modulorails::SuccessData.new(data)
  rescue ActiveRecord::RecordInvalid => e
    # Known error, no need for a log, it just needs to be returned
    ::Modulorails::ErrorData.new(e.message, exception: e)
  rescue StandardError => e
    # Unknown error, log the error
    log_exception(e, caller: self, method: __method__)

    # Return the error
    ::Modulorails::ErrorData.new(e.message, exception: e)
  end

  def log_exception(exception, user: nil, caller: self, method: __method__)
    message = {
      controller: caller.class.name, action: method,
      error: { kind: exception.class.name, message: exception.message, stack: exception.backtrace },
      time: Time.zone.now.iso8601, user: user
    }

    Rails.logger.error(message.to_json)
  end

  # Cast the date/datetime parameters to time with zones.
  # @param from [String,ActiveSupport::TimeWithZone] the minimum date
  # @param to [String,ActiveSupport::TimeWithZone] the maximum date
  # @return [[ActiveSupport::TimeWithZone, ActiveSupport::TimeWithZone]] The given dates casted.
  def params_to_time(from, to=nil)
    from = from.is_a?(String) && from.present? ? from.to_time_with_zone : from
    to   = if to.is_a?(String) && to.present?
             to = to.to_time_with_zone

             # If the right bound is exactly the same as the left one, we add 1 day to the right
             # one by default.
             to.present? && to == from ? to + 1.day : to
           else
             to
           end

    [from, to]
  end

  # Shamelessly copied from text_helper
  def pluralize(count, singular, plural_arg=nil, plural: plural_arg, locale: I18n.locale)
    self.class.pluralize(count, singular, plural_arg, plural: plural, locale: locale)
  end

  # Take a series of keys, dig them into the given params and ensure the found value is a date.
  # @param keys [Array<Symbol>] The keys to find in the parameters.
  # @param params [#dig] The parameters to dig in.
  # @return [ActiveSupport::TimeWithZone] If it is found, the value casted as a datetime.
  # @return [nil] If the parameter was not found.
  def parse_date_field(*keys, params:)
    value = params.dig(*keys)

    return nil unless value

    begin
      Time.zone.parse(value)
    rescue ArgumentError
      raise InvalidFormatError.new(keys.join('/'))
    end
  end

  # Take a series of keys, dig them into the given params and ensure the found value is a date.
  # @param keys [Array<Symbol>] The keys to find in the parameters.
  # @param params [#dig] The parameters to dig in.
  # @return [ActiveSupport::TimeWithZone] If it is found, the value casted as a datetime.
  # @return [nil] If the parameter was not found.
  def parse_iso8601_field(*keys, params: {})
    value = params.dig(*keys)

    return nil unless value

    begin
      Time.zone.iso8601(value)
    rescue ArgumentError
      raise InvalidFormatError.new(keys.join('/'))
    end
  end

  # Take a series of keys, dig them into the given params and ensure the found value is valid.
  # @param allowed_values [#include?] Allowed values
  # @param keys [Array<Symbol>] The keys to find in the parameters.
  # @param params [#dig] The parameters to dig in.
  # @param allow_nil [Boolean] Do not raise if value is nil.
  # @return [ActiveSupport::TimeWithZone] If it is found, the value casted as a datetime.
  # @return [nil] If the parameter was not found.
  def parse_enumerated_field(allowed_values, keys, params: {}, allow_nil: true)
    value = params.dig(*keys)

    if value.respond_to?(:each)
      raise InvalidValueError.new(keys.join('/')) unless value.all? { |v|
        allowed_values.include?(v)
      }
    else
      return nil if !value && allow_nil

      raise InvalidValueError.new(keys.join('/')) unless allowed_values.include?(value)
    end

    value
  end

  # @param model [#find_by] The model to search in
  # @param field [Symbol] The field to filter on
  # @param keys [Array<Symbol>] The keys to search in the params
  # @param params [#dig] The params to search in
  # @param allow_nil [Boolean] Raise if the keys are not found; default true
  # @return [#id, nil] The record corresponding to given field and values (through keys)
  # @raise [InvalidValueError] When there is no record for given field and values
  def parse_referential_value(model, field, *keys, params: {}, allow_nil: true)
    value = params.dig(*keys)

    unless value
      return nil if allow_nil

      raise InvalidValueError.new(keys.join('/'))
    end

    result = model.find_by(field => value)

    raise InvalidValueError.new(keys.join('/')) if result.nil?

    result
  end

  # @param model [#where] The model to search in
  # @param field [Symbol] The field to filter on
  # @param keys [Array<Symbol>] The keys to search in the params
  # @param params [#dig] The parmas to search in
  # @param allow_nil [Boolean] Raise if the keys are not found; default true
  # @return [#ids, nil] The record corresponding to given field and values (through keys)
  # @raise [InvalidValueError] When there is no record for given field and values
  def parse_referential_values(model, field, *keys, params: {}, allow_nil: true)
    values = params.dig(*keys)

    if values.blank?
      return nil if allow_nil

      raise InvalidValueError.new(keys.join('/'))
    end

    results = model.where(field => values)

    raise InvalidValueError.new(keys.join('/')) if results.blank?

    results
  end

end
