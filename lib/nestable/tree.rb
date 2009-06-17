module Nestable
  # Example table:
  #
  #   +------+---------+-------------+
  #   |  id  |  name   |  parent_id  |
  #   +------+---------+-------------+
  #   |  1   |  food   |     NULL    |
  #   |  2   |  fruit  |      1      |
  #   |  3   |  sour   |      2      |
  #   |  4   |  sweet  |      2      |
  #   |  5   |  meat   |      1      |
  #   |  6   |  beef   |      5      |
  #   |  7   |  pork   |      5      |
  #   +------+---------+-------------+
  #
  # Pros: 
  #
  # * Quick inserts and updates - it only needs to set a foreign key on the current node which references its parent node
  #
  # Cons: 
  #
  # * Slow reads - it's inefficient for fetching large trees since one query is required for each level in a tree
  #
  # Options:
  #
  #   :class_name       -  The class name to use for the parent and children associations. Defaults to the name of the current class.
  #   :level_column     -  The name of the column that stores the number of ancestors a node has. This column is optional. If you
  #                        decide not to store this field, the level of a node is calculated by recursively fetching its parents 
  #                        and counting them. Defaults to nil.
  #   :order            -  The default order to use when collecting children, descendants, siblings, etc. Defaults to nil.
  #   :parent_column *  -  The name of the foreign key that references the parent of a node. Defaults to :parent_id.
  #   :scope            -  A field or an array of fields to scope trees to. Defaults to an empty array.
  #
  #   * Signifies a required field which must exist in your database
  #
  #     :level_column   -  integer (if you decide to store it)
  #     :parent_column  -  integer
  module Tree
    
    def self.included(base) # :nodoc:
      base.class_eval do
        belongs_to :parent, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:parent_column]
        has_many :children, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:parent_column], :dependent => :destroy, :order => nestable_options[:order]
        validate :ensure_parent_exists_in_nestable_scope
        validate_on_update :ensure_parent_column_does_not_reference_self_and_descendants
        
        before_save :set_level_column_value
        
        named_scope :leaves, :conditions => "NOT EXISTS (SELECT * FROM #{table_name} #{table_name}_children WHERE #{nestable_options[:parent_column]} = #{table_name}.#{primary_key})", :order => nestable_options[:order]
        named_scope :roots, :conditions => { nestable_options[:parent_column] => nil }, :order => nestable_options[:order]
      end if base.ancestors.include?(ActiveRecord::Base)
    end
    
    def self.process_options!(options) # :nodoc:
      options = { :dependent => :destroy, :parent_column => :parent_id, :scope => [] }.merge(options)
      options[:class_name] ||= options[:class].name
      options[:order] = Array(options[:order]).map { |order| order.is_a?(Symbol) ? "#{options[:class].table_name}.#{order}" : order }.join(', ') unless options[:order].nil?
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
      nestable_scope.scoped(:conditions => { self.class.nestable_options[:parent_column] => id })
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
    
    def flatten! # :nodoc:
      descendants.each { |descendant| descendant.update_attribute(self.class.nestable_options[:parent_column], parent_column_value) }
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
      level_column_value
    end
    
    # Returns the value of a node's <tt>:level_column</tt> or calculates it if it's not stored
    def level_column_value
      self.class.nestable_options[:level_column].nil? ? ancestors.size : self[self.class.nestable_options[:level_column]]
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
    
    # Returns true if a node's <tt>:parent_column</tt> value was changed, false otherwise
    def parent_column_value_changed?
      send("#{self.class.nestable_options[:parent_column]}_changed?")
    end
    
    # Returns the old value of a node's <tt>:parent_column</tt> if it was was changed
    def parent_column_value_was
      send("#{self.class.nestable_options[:parent_column]}_was")
    end
    
    def root # :nodoc:
      is_root? ? self : ancestors.last
    end
    
    def root_ids # :nodoc:
      roots.map(&:id)
    end
    
    def roots # :nodoc:
      nestable_scope.roots
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
        unless !parent_column_value_changed? || parent_column_value.nil? || nestable_scope.scoped(:conditions => { :id => parent_column_value }).first
          errors.add(self.class.nestable_options[:parent_column], 'does not exist')
        end
      end
      
      def ensure_parent_column_does_not_reference_self_and_descendants # :nodoc:
        if parent_column_value_changed? &&  self_and_descendant_ids.include?(parent_column_value)
          errors.add(self.class.nestable_options[:parent_column], "can't be a reference to the current node or any of its descendants")
        end
      end
      
      def set_level_column_value # :nodoc:
        unless self.class.nestable_options[:level_column].nil? || (!parent_column_value_changed? && !new_record?)
          send("#{self.class.nestable_options[:level_column]}=".to_sym, parent.nil? ? 0 : parent.level + 1)
        end
      end
    
  end
end