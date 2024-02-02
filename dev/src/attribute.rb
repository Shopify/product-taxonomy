require_relative 'storage/memory'

class Attribute
  include Comparable

  attr_reader :id, :name, :values

  class << self
    def find(id)
      Storage::Memory.find(self, id)
    end

    def find!(id)
      Storage::Memory.find!(self, id)
    end

    def from_json(json)
      new(
        id: json["id"],
        name: json["name"],
        values: json["values"].map { AttributeValue.from_json(_1) },
      )
    end
  end

  def initialize(id:, name:, values: [])
    @id = id.to_s
    @name = name
    @values = values

    Storage::Memory.save(self.class, id, self)
  end

  def gid
    @gid ||= "gid://shopify/Taxonomy/Attribute/#{id}"
  end

  def add_value(value)
    values << value
    values.sort!
    values
  end

  def to_h
    {
      id: gid,
      name:,
    }
  end

  def inspect
    "#<#{self.class} id=`#{id}` name=`#{name}` values=`#{values.map(&:id)}`>"
  end

  def serialize_as_hash
    {
      id: gid,
      name:,
      values: values.map(&:to_h),
    }
  end

  def <=>(other)
    return nil if other.nil? || !other.is_a?(self.class)

    name <=> other.name
  end
end
