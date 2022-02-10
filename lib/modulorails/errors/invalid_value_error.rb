# @author Matthieu CIAPPARA <ciappa_m@modulotech.fr>
# An exception representing an invalid value for a given field.
class Modulorails::InvalidValueError < Modulorails::BaseError
  # @!attribute r field
  #   The name of the field that had a wrong value.
  attr_reader :field

  # @param field [String]
  def initialize(field)
    super(I18n.t('modulorails.errors.invalid_value', field: field))

    @field = field
  end
end
