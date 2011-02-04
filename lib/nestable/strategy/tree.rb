module Nestable # :nodoc:
  module Strategy # :nodoc:
    # Example table:
    #
    #   +------+---------+-------------+--------------------+
    #   |  id  |  name   |  parent_id  |  level [optional]  |
    #   +------+---------+-------------+--------------------+
    #   |  1   |  food   |     NULL    |         0          |
    #   |  2   |  fruit  |      1      |         1          |
    #   |  3   |  sour   |      2      |         2          |
    #   |  4   |  sweet  |      2      |         2          |
    #   |  5   |  meat   |      1      |         1          |
    #   |  6   |  beef   |      5      |         2          |
    #   |  7   |  pork   |      5      |         2          |
    #   +------+---------+-------------+--------------------+
    #
    # Pros:
    #
    # * Quick inserts, updates, and wide tree reads - it only needs to set a foreign key on the current node which references its parent node
    #
    # Cons:
    #
    # * Slow reads for deep trees - one query is required for each level in a tree
    #
    # Options:
    #
    #   :class_name     -  The class name to use for the parent and children associations. Defaults to the name of the current class.
    #   :level_column   -  The name of the column that stores the number of ancestors a node has. If you decide not to store this
    #                      field, the level of a node is calculated by recursively fetching its parents.
    #                      and counting them. Defaults to :level.
    #   :parent_column  -  [REQUIRED] The name of the foreign key that references the parent of a node. Defaults to :parent_id.
    #   :scope          -  A field or an array of fields to scope nodes to.
    module Tree
      def self.included(base) # :nodoc:
        base.class_eval do
          nestable_options.merge!(:scope => Array(nestable_options[:scope])).reverse_merge!(:class_name => name, :dependent => :destroy, :parent_column => :parent_id)

          belongs_to :parent, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:parent_column]
          has_many :children, :class_name => nestable_options[:class_name], :foreign_key => nestable_options[:parent_column], :dependent => nestable_options[:dependent]

          scope :leaves, where("NOT EXISTS (SELECT * FROM #{table_name} #{table_name}_children WHERE #{nestable_options[:parent_column]} = #{table_name}.#{primary_key})")
          scope :roots, where(nestable_options[:parent_column] => nil)

          validate :nestable_parent_exists
          validate :nestable_parent_does_not_reference_self_or_descendants, :on => :update

          before_save :set_nestable_level
        end
      end

      def ancestor_ids # :nodoc:
        ancestors.map(&:id)
      end

      def ancestors # :nodoc:
        node, nodes = self, []
        nodes << node = node.parent while node.parent
        nodes
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
        if attribute_method?(:level)
          super
        elsif !['', 'false', 'level'].include?(nestable_options[:level_column].to_s)
          send(nestable_options[:level_column])
        else
          ancestors.size
        end
      end

      def level=(level) # :nodoc:
        if attribute_method?(:level)
          super
        elsif !['', 'false', 'level'].include?(nestable_options[:level_column].to_s)
          send("#{nestable_options[:level_column]}=", level)
        end
      end

      # Returns an anonymous scope of <tt>:conditions</tt> and <tt>:order</tt> referencing the same <tt>:scope</tt> as the current node
      #
      # Example:
      #
      #   class Category < ActiveRecord::Base
      #     nestable :scope => :site_id
      #   end
      #
      #   @category = Category.find(13)
      #
      #   @category.nestable_scope.all # Returns categories with the same :site_id as @category
      def nestable_scope
        self.class.base_class.where(self.class.nestable_options[:scope].inject({}) { |scope, field| scope.merge!(field => send(field)) })
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
        nestable_scope.where(self.class.nestable_options[:parent_column] => parent_column_value)
      end

      def sibling_ids # :nodoc:
        siblings.map(&:id)
      end

      def siblings # :nodoc:
        self_and_siblings.where("#{self.class.table_name}.#{self.class.primary_key} != ?", id)
      end

      protected

        def nestable_parent_exists # :nodoc:
          unless !parent_column_value_changed? || parent_column_value.nil? || nestable_scope.exists?(parent_column_value)
            message = I18n.t('nestable.strategy.tree.non_existent_parent_error', :default => 'does not exist')
            errors.add(self.class.nestable_options[:parent_column], message)
          end
        end

        def nestable_parent_does_not_reference_self_or_descendants # :nodoc:
          if parent_column_value_changed? &&  self_and_descendant_ids.include?(parent_column_value)
            message = I18n.t('nestable.strategy.tree.self_or_descendant_parent_error', :default => "can't reference the current node or any of its descendants")
            errors.add(self.class.nestable_options[:parent_column], message)
          end
        end

        def set_nestable_level # :nodoc:
          self.level = parent ? parent.level + 1 : 0 if parent_column_value_changed? || new_record?
        end
    end
  end
end