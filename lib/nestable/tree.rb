module Nestable
  module Tree
    
    def self.included(base)
      base.class_eval do
        belongs_to :parent, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:foreign_key]
        has_many :children, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:foreign_key], :order => nestable_options[:order], :dependent => :destroy
        validate_on_update :ensure_foreign_key_does_not_reference_self_and_descendants
      end
    end
    
    def self.validate_nestable_options(options)
      options = { :foreign_key => :parent_id, :scope => [] }.merge(options)
      options[:class_name] ||= options[:class].name
      options[:order] = "#{table_name}.#{options[:order]}" if options[:order].is_a?(Symbol)
      options
    end
    
    def ancestors
      node, nodes = self, []
      nodes << node = node.parent while node.parent
      nodes
    end
    
    def descendants
      children.inject([]) { |descendants, node| [node] + node.descendants }.flatten
    end
    
    def is_ancestor_of(node)
      node.ancestors.include?(self)
    end
    
    def is_descendant_of(node)
      node.is_ancestor_of(self)
    end
    
    def is_sibling_of(node)
      node.siblings.include?(self)
    end
    
    def is_root?
      !new_record? && send(self.class.nestable_options[:foreign_key]).nil?
    end
    
    def leaves
      children.map { |child| child.children.empty? ? [child] : child.leaves }.flatten
    end
    
    def level
      ancestors.size
    end
    
    def root
      ancestors.last
    end
    
    def roots
      conditions = nestable_scope
      conditions.first << "#{self.class.table_name}.#{options[:foreign_key]} IS NULL"
      self.class.all :conditions => conditions, :order => self.class.nestable_options[:order]
    end
    
    def self_and_ancestors
      [self] + ancestors
    end
    
    def self_and_descendants
      [self] + descendants
    end
    
    def self_and_siblings
      [self] + siblings
    end
    
    def siblings
      (is_root? ? roots : parent.children) - [self]
    end
    
    protected
    
      def ensure_foreign_key_does_not_reference_self_and_descendants
        foreign_key = self.class.nestable_options[:foreign_key]
        referenced_node_id = send(foreign_key)
        self.errors.add(foreign_key, "can't be a reference to the current node or any of its descendants") if self_and_descendants.detect { |node| node.id == referenced_node_id }
      end
      
      def nestable_scope
        self.class.nestable_options[:scope].inject(["1 = 1"]) do |conditions, scope|
          conditions.first << " AND #{self.class.table_name}.#{scope} "
          value = send(scope)
          if value.nil?
            conditions.first << 'IS NULL'
          else
            conditions.first << '= ?'
            conditions << value
          end
        end
      end
    
  end
end