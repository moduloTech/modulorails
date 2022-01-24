# @author Matthieu CIAPPARA <ciappa_m@modulotech.fr>
# An exception representing an invalid format for a given field.
class Modulorails::InvalidFormatError < Modulorails::BaseError
  # @!attribute r field
  #   The name of the field that had a wrong format.
  attr_reader :field

  # @param field [String]
  def initialize(field)
    super(I18n.t('modulorails.errors.invalid_format', field: field))

    @field = field
  end
end
