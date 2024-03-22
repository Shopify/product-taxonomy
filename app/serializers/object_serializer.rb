# frozen_string_literal: true

class ObjectSerializer
  include Singleton

  class << self
    delegate(:serialize, :deserialize, to: :instance)
  end

  def serialize(object)
    object.as_json
  end

  def deserialize(hash)
    raise NotImplementedError
  end
end
