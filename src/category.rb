class Category
  include Comparable

  attr_reader(
    :id,
    :name,
    :level,
  )

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
        id: json["public_id"],
        name: json["name"],
        level: json["level"] - 1,
        parent: json["parent_id"],
        children: json["children_ids"],
        attributes: json["attribute_ids"],
      )
    end
  end

  # allow ids passing for delayed instantiation
  def initialize(id:, name:, level: 0, parent: nil, children: [], attributes: [])
    @id = id
    @name = name
    @level = level

    if parent.is_a?(self.class)
      @parent = parent
    else
      @parent_id = parent
    end

    if children.all? { _1.is_a?(self.class) }
      @children = children
    else
      @children_ids = children
    end

    # TODO: model attributes
    @attribute_ids = attributes

    @@nodes[id] = self
  end

  def parent
    @parent ||= self.class.find!(@parent_id)
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

  def root
    root = self
    root = root.parent until root.root?
    root
  end

  def root?
    parent.nil?
  end

  def leaf?
    children.empty?
  end

  def add(child)
    raise ArgumentError, "nil children not allowed" if child.nil?
    raise ArgumentError, "cannot add root as child" if child == root
    raise ArgumentError, "cannot add self as child" if child == self
    raise ArgumentError, "cannot add an ancestor as child" if ancestors.include?(child)

    child.parent = self
    children << child
    child
  end

  def ancestors
    return @ancestors if defined?(@ancestors)

    @ancestors = if parent.nil?
      Set[]
    else
      Set[parent] + parent.ancestors
    end
  end

  def descendants
    return @descendants if defined?(@descendants)

    @descendants = Set[children] + children.flat_map(&:descendants)
  end

  def fully_qualified_type
    ancestors.to_a.reverse.map(&:name).push(name).join(" > ")
  end

  def to_h
    {
      id: gid,
      name:,
    }
  end

  def to_full_hash
    {
      fully_qualified_type:,
      id: gid,
      name:,
      parent_id: parent&.gid,
      level:,
      children: children.map(&:to_h),
      ancestors: ancestors.map(&:to_h),
      attribute_ids: attributes.map { _1[:gid] },
    }
  end

  def to_s
    "#{gid} : #{fully_qualified_type}"
  end

  def <=>(other)
    return nil if other.nil? || !other.is_a?(self.class)

    id <=> other.id
  end

  protected

  def parent=(parent)
    @parent = parent
    @level = parent ? parent.level + 1 : 0
    remove_instance_variable(:@ancestors) if defined?(@ancestors)
    remove_instance_variable(:@descendants) if defined?(@descendants)
  end
end
