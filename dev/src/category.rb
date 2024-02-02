require_relative 'attribute'
require_relative 'storage/memory'

class Category
  include Comparable

  @@largest_gid = 0

  attr_reader(:id, :name, :level)

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
        level: json["level"] - 1,
        parent: json["parent_id"],
        children: json["children_ids"],
        attributes: json["attribute_ids"],
      )
    end
  end

  # allow ids passing for delayed instantiation
  def initialize(id:, name:, level: 0, parent: nil, children: [], attributes: [])
    @id = id.to_s
    @name = name
    @level = level

    if parent.is_a?(self.class)
      @parent = parent
    else
      @parent_id = parent
    end

    if children.all? { _1.is_a?(self.class) }
      @children = children.sort
    else
      @children_ids = children || []
    end

    if attributes.all? { _1.is_a?(Attribute) }
      @attributes = attributes.sort
    else
      @attribute_ids = attributes || []
    end

    Storage::Memory.save(self.class, id, self)
    @@largest_gid = [@@largest_gid, gid.size].max
  end

  def parent
    @parent ||= self.class.find!(@parent_id)
  end

  def children
    @children ||= @children_ids.map { self.class.find!(_1) }.sort!
  end

  def attributes
    @attributes ||= @attribute_ids.map { Attribute.find!(_1) }.sort!
  end

  def gid
    @gid ||= "gid://shopify/Taxonomy/Category/#{id.downcase}"
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
    children.sort!
    child
  end

  def ancestors
    return @ancestors if defined?(@ancestors)

    @ancestors = if parent.nil?
      []
    else
      [parent] + parent.ancestors
    end
  end

  def ancestors_and_self
    [self] + ancestors
  end

  # depth-first given that matches how we want to use this
  def descendants
    return @descendants if defined?(@descendants)

    @descendants = children.flat_map { |child| [child] + child.descendants }
  end

  def descendants_and_self
    [self] + descendants
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
    "#<#{self.class} id=`#{id}` name=`#{name}` parent=`#{parent&.id}` children=`#{children.size}`>"
  end

  def serialize_as_hash
    {
      id: gid,
      level:,
      name:,
      full_name:,
      parent_id: parent&.gid,
      attributes: attributes.map(&:to_h),
      children: children.map(&:to_h),
      ancestors: ancestors.map(&:to_h),
    }
  end

  def serialize_as_txt
    "#{gid.ljust(@@largest_gid)} : #{full_name}"
  end

  def <=>(other)
    return nil if other.nil? || !other.is_a?(self.class)

    name <=> other.name
  end

  protected

  def parent=(parent)
    @parent = parent
    @level = parent ? parent.level + 1 : 0
    remove_instance_variable(:@ancestors) if defined?(@ancestors)
    remove_instance_variable(:@descendants) if defined?(@descendants)
  end
end
