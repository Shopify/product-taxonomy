# frozen_string_literal: true

module ProductTaxonomy
  module FormattedValidationErrors
    def validate!(...)
      super # Calls original ActiveModel::Validations#validate!
    rescue ActiveModel::ValidationError
      id_field_name = self.is_a?(Category) ? :id : :friendly_id
      id_value = self.send(id_field_name)

      formatted_error_details = self.errors.map do |error|
        attribute = error.attribute # Raw attribute name, e.g., :friendly_id
        message = error.message     # Just the message part, e.g., "can't be blank"
        prefix = "  • "

        prefix + (attribute == :base ? message : "#{attribute} #{message}")
      end.join("\n")

      raise ActiveModel::ValidationError.new(self), "Validation failed for #{self.class.name.demodulize.downcase} " \
        "with #{id_field_name}=`#{id_value}`:\n#{formatted_error_details}"
    end
  end
end
