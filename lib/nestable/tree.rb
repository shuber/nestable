module Nestable
  # Pros: 
  #
  # * Simple and elegant - only requires a foreign key which references a node's parent.
  # * Quick writes
  #
  # Cons: 
  #
  # * Can be slow and inefficient for fetching large trees due to recursion - one query is required for each level in a tree.
  #
  # Options:
  #
  #   :class_name     -  The class name to use for the parent and children associations. Defaults to the name of the current class.
  #   :dependent      -  The dependent option for the children association. Defaults to :destroy.
  #   :order          -  The default order to use when collecting children, descendants, siblings, etc. Defaults to nil.
  #   :parent_column  -  The name of the foreign key that references a node's parent. Defaults to :parent_id.
  #   :scope          -  A field or an array of fields to scope trees to. Defaults to an empty array.
  module Tree
    
    def self.included(base) # :nodoc:
      base.class_eval do
        belongs_to :parent, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:parent_column]
        has_many :children, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:parent_column], :dependent => nestable_options[:dependent], :order => nestable_options[:order]
        validate :ensure_parent_exists_in_nestable_scope
        validate_on_update :ensure_parent_column_does_not_reference_self_and_descendants
      end if base.ancestors.include?(ActiveRecord::Base)
    end
    
    def self.process_options!(options) # :nodoc:
      options = { :dependent => :destroy, :parent_column => :parent_id, :scope => [] }.merge(options)
      options[:class_name] ||= options[:class].name
      options[:order] = Array(options[:order]).map { |order| order.is_a?(Symbol) ? "#{self.class.table_name}.#{order}" : order }.join(', ') unless options[:order].nil?
      options[:scope] = Array(options[:scope])
      options
    end
    
    def ancestor_ids # :nodoc:
      ancestors.map(&:id)
    end
    
    def ancestors # :nodoc:
      node, nodes = self, []
      nodes << node = node.parent while node.parent
      nodes
    end
    
    def children # :nodoc:
    end
    
    def children_ids # :nodoc:
      children.map(&:id)
    end
    
    def descendant_ids # :nodoc:
      descendants.map(&:id)
    end
    
    def descendants # :nodoc:
      children.inject([]) { |descendants, node| descendants += [node] + node.descendants }.flatten
    end
    
    def is_ancestor_of?(node) # :nodoc:
      node.ancestors.include?(self)
    end
    
    def is_descendant_of?(node) # :nodoc:
      node.is_ancestor_of?(self)
    end
    
    def is_sibling_of?(node) # :nodoc:
      node.siblings.include?(self)
    end
    
    def is_root? # :nodoc:
      !new_record? && parent_column_value.nil?
    end
    
    def leave_ids # :nodoc:
      leaves.map(&:id)
    end
    
    def leaves # :nodoc:
      children.map { |child| child.children.empty? ? [child] : child.leaves }.flatten
    end
    
    def level # :nodoc:
      ancestors.size
    end
    
    # Returns an anonymous scope of <tt>:conditions</tt> and <tt>:order</tt> referencing the same <tt>:scope</tt> as the current node
    #
    # Example:
    #
    #   class Category < ActiveRecord::Base
    #     nestable :scope => :site_id, :order => :name
    #   end
    #
    #   @category = Category.find(13)
    #
    #   # Returns categories with the same :site_id as @category ordered by name
    #   @category.nestable_scope.all
    def nestable_scope
      scope = self.class.nestable_options[:scope].inject({}) { |scope, field| scope.merge!(field => send(field)) }
      self.class.base_class.scoped(
        :conditions => scope.empty? ? nil : scope,
        :order => self.class.nestable_options[:order]
      )
    end
    
    def parent # :nodoc:
    end
    
    # Returns the value of a node's <tt>:parent_column</tt>
    def parent_column_value
      send(self.class.nestable_options[:parent_column])
    end
    
    def root # :nodoc:
      is_root? ? self : ancestors.last
    end
    
    def root_ids # :nodoc:
      roots.map(&:id)
    end
    
    def roots # :nodoc:
      nestable_scope.scoped(:conditions => { self.class.nestable_options[:parent_column] => nil })
    end
    
    def self_and_ancestor_ids # :nodoc:
      self_and_ancestors.map(&:id)
    end
    
    def self_and_ancestors # :nodoc:
      [self] + ancestors
    end
    
    def self_and_children # :nodoc:
      [self] + children
    end
    
    def self_and_children_ids # :nodoc:
      self_and_children.map(&:id)
    end
    
    def self_and_descendant_ids # :nodoc:
      self_and_descendants.map(&:id)
    end
    
    def self_and_descendants # :nodoc:
      [self] + descendants
    end
    
    def self_and_sibling_ids # :nodoc:
      self_and_siblings.map(&:id)
    end
    
    def self_and_siblings # :nodoc:
      nestable_scope.scoped(:conditions => { self.class.nestable_options[:parent_column] => parent_column_value })
    end
    
    def sibling_ids # :nodoc:
      siblings.map(&:id)
    end
    
    def siblings # :nodoc:
      self_and_siblings.scoped(:conditions => ["#{self.class.table_name}.#{self.class.primary_key} <> ?", id])
    end
    
    protected
    
      def ensure_parent_exists_in_nestable_scope # :nodoc:
        self.errors.add(self.class.nestable_options[:parent_column], 'does not exist') unless parent_column_value.nil? || nestable_scope.scoped(:conditions => { :id => parent_column_value }).first
      end
      
      def ensure_parent_column_does_not_reference_self_and_descendants # :nodoc:
        self.errors.add(self.class.nestable_options[:parent_column], "can't be a reference to the current node or any of its descendants") if self_and_descendant_ids.include?(parent_column_value)
      end
    
  end
end