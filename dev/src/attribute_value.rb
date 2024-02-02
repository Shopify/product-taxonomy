class AttributeValue
  include Comparable

  attr_reader :id, :name

  class << self
    def from_json(json)
      new(
        id: json["id"],
        name: json["name"],
      )
    end
  end

  def initialize(id:, name:)
    @id = id.to_s
    @name = name
  end

  def gid
    @gid ||= "gid://shopify/Taxonomy/Attribute/#{id.gsub('-', '/')}"
  end

  def to_h
    {
      id: gid,
      name:,
    }
  end

  def inspect
    "#<#{self.class} id=`#{id}` name=`#{name}`>"
  end

  def <=>(other)
    return nil if other.nil? || !other.is_a?(self.class)

    return 1 if name == 'Other'
    return -1 if other.name == 'Other'

    name <=> other.name
  end
end
