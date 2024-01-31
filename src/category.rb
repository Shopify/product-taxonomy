class Category
  include Comparable

  @@nodes = {}
  @@largest_gid = 0

  attr_reader(:id, :name, :level)

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
        id: json["public_id"],
        name: json["name"],
        level: json["level"] - 1, # source files are 1-based
        parent_id: json["parent_id"],
        children_ids: json["children_ids"],
        attribute_ids: json["attribute_ids"],
      )
    end
  end

  # tree is parsed into @@nodes before interaction, therefore is static
  def initialize(id:, name:, level: 0, parent_id: nil, children_ids: [], attribute_ids: [])
    @id = id
    @name = name
    @level = level

    @parent_id = parent_id
    @children_ids = children_ids
    @attribute_ids = attribute_ids

    @@nodes[id] = self
    @@largest_gid = [@@largest_gid, gid.size].max
  end

  def parent
    return @parent if defined?(@parent)

    @parent = self.class.find!(@parent_id)
  end

  def children
    @children ||= @children_ids.map { self.class.find!(_1) }
  end

  def attributes
    @attributes ||= @attribute_ids.map do |id|
      # for now, good enough...
      {
        id:,
        gid: "gid://shopify/Taxonomy/Attribute/#{id}",
      }
    end
  end

  def gid
    "gid://shopify/Taxonomy/Category/#{id.downcase}"
  end

  def full_name
    @full_name ||= ancestors.reverse.map(&:name).push(name).join(" > ")
  end

  def ancestors
    return @ancestors if defined?(@ancestors)

    @ancestors = if parent.nil?
      []
    else
      [parent] + parent.ancestors
    end
  end

  def descendants
    return @descendants if defined?(@descendants)

    @descendants = children + children.flat_map(&:descendants)
  end

  def to_h
    {
      id: gid,
      name:,
    }
  end

  def to_s
    "#{full_name} (#{gid})"
  end

  def <=>(other)
    return nil if other.nil? || !other.is_a?(self.class)

    id <=> other.id
  end

  def serialize_as_hash
    {
      id: gid,
      level:,
      name:,
      full_name:,
      parent_id: parent&.gid,
      attributes: attributes.map do |attr|
        { id: attr[:gid] }
      end,
      children: children.map(&:to_h),
      ancestors: ancestors.map(&:to_h),
    }
  end

  def serialize_as_txt
    "#{gid.ljust(@@largest_gid)} : #{full_name}"
  end

  protected

  def parent=(parent)
    @parent = parent
    @level = parent ? parent.level + 1 : 0
    remove_instance_variable(:@ancestors) if defined?(@ancestors)
    remove_instance_variable(:@descendants) if defined?(@descendants)
  end
end
