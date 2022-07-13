# @author Matthieu Ciappara <ciappa_m@modulotech>
# An error encountered during an operation with additional data.
class Modulorails::ErrorData

  # @!attribute r errors
  #   An error message or an array of error messages (those will be joined by a coma and a space).
  # @!attribute r exception
  #   The exception that caused the error. Defaults to nil.
  attr_reader :errors, :exception

  # @param errors [String,Array<String>] An error message or an array of error messages
  # @param exception [Exception,nil] The exception that caused the error.
  def initialize(errors, exception: nil)
    @errors    = errors.respond_to?(:join) ? errors.join(', ') : errors.to_s
    @exception = exception
  end

  # @return [false] An error always means the operation was not a success.
  def success?
    false
  end

end
