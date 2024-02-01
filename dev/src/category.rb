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

    def from_json(json, attribute_names_by_id)
      new(
        id: json["id"],
        name: json["name"],
        level: json["level"] - 1,
        parent: json["parent_id"],
        children: json["children_ids"],
        attributes: json["attribute_ids"],
        attribute_names_by_id: attribute_names_by_id,
      )
    end
  end

  # allow ids passing for delayed instantiation
  def initialize(id:, name:, level: 0, parent: nil, children: [], attributes: [], attribute_names_by_id: nil)
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
    @attribute_names_by_id = attribute_names_by_id

    @@nodes[id] = self
    @@largest_gid = [@@largest_gid, gid.size].max
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
        name: @attribute_names_by_id[id],
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

    @descendants = children.reduce(children.to_set) do |set, child|
      set + child.descendants
    end
  end

  def full_name
    ancestors.to_a.reverse.map(&:name).push(name).join(" > ")
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

  def inspect
    "#<#{self.class} id=#{id} name=#{name} parent=#{parent.id} children=#{children.map(&:id)}>"
  end

  def serialize_as_hash
    {
      id: gid,
      level:,
      name:,
      full_name:,
      parent_id: parent&.gid,
      attributes: attributes.map { { id: _1[:gid], name: _1[:name] } },
      children: children.map(&:to_h),
      ancestors: ancestors.map(&:to_h),
    }
  end

  def serialize_as_txt
    "#{gid.ljust(@@largest_gid)} : #{full_name}"
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
