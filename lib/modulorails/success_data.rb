# @author Matthieu Ciappara <ciappa_m@modulotech>
# A success resulting from an operation with optional additional data.
class Modulorails::SuccessData

  # @!attribute r data
  #   An object to transport some data (for instance the result of the operation). Defaults to nil.
  attr_reader :data

  # @param data [Object] An object to transport some data (for instance the result of the operation)
  def initialize(data=nil)
    @data = data
  end

  # @return [true] A success always means the operation was a success. ;)
  def success?
    true
  end

end
