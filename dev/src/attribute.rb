class Attribute
  @@nodes = {}

  class << self
    def find(id)
      return if id.nil? || id.empty?

      @@nodes[id]
    end

    def find!(id)
      return if id.nil? || id.empty?

      find(id) || raise(ArgumentError, "no category with id #{id}")
    end

    def from_json(json)
      new(
        id: json["id"],
        name: json["name"],
        values: json["values"].map { AttributeValue.from_json(_1) },
      )
    end
  end

  attr_reader :id, :name, :values

  def initialize(id:, name:, values: [])
    @id = id
    @name = name
    @values = values

    @@nodes[id] = self
  end

  def gid
    @gid ||= "gid://shopify/Taxonomy/Attribute/#{id}"
  end

  def add_value(value)
    values << value
  end

  def to_h
    {
      id: gid,
      name:,
    }
  end

  def serialize_as_hash
    {
      id: gid,
      name:,
      values: values.map(&:to_h),
    }
  end
end
