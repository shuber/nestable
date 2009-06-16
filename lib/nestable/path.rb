module Nestable
  # Pros:
  #
  # * Quick inserts - it only needs to calculate the <tt>:path_column</tt> on the current node by looking up its parent's <tt>:path_column</tt> and <tt>:segment_column</tt>
  # * Quick reads - it can fetch a node and all of its descendants in a single query
  #
  # Cons:
  #
  # * Slow updates - the <tt>:path_column</tt> must be re-calculated once for every level of a node's descendants (if it was changed)
  #
  # Options:
  #
  #   :class_name         -  The class name to use for the parent and children associations. Defaults to the name of the current class.
  #   :dependent          -  The dependent option for the children association. Defaults to :destroy.
  #   :level              -  The name of the column that stores the number of ancestors a node has. Defaults to :level.
  #   :order              -  The default order to use when collecting children, descendants, siblings, etc. Defaults to nil.
  #   :parent_column      -  The name of the foreign key that references a node's parent. Defaults to :parent_id.
  #   :path_column        -  The name of the column that references a node's ancestry path. Defaults to :path.
  #   :scope              -  A field or an array of fields to scope trees to. Defaults to an empty array.
  #   :segment_column     -  The name of the column to use when calculating a node's path. Defaults to :id.
  #   :segment_delimiter  -  The delimiter to use when separating segments and storing paths. Defaults to '/'
  module Path
    
    include Nestable::Tree
    
    def self.included(base) # :nodoc:
      Nestable::Tree.included(base)
      base.class_eval do
        before_save :set_path_column_value
        after_update :update_child_path_column_values
        alias_method_chain :reload, :nestable_path
      end
    end
    
    def self.process_options!(options) # :nodoc:
      options = { :level_column => :level, :path_column => :path, :segment_column => :id, :segment_delimiter => '/' }.merge(options)
      table_name = options[:class].table_name
      options[:order] = ["#{table_name}.#{options[:path_column]} || #{table_name}.#{options[:segment_column]} || '#{options[:segment_delimiter]}' || (#{table_name}.#{options[:level_column]}/10000000000)", options[:order]].reject(&:blank?).join(', ')
      Nestable::Tree.process_options!(options)
    end
    
    def descendants # :nodoc:
      self_and_descendants.scoped(
        :conditions => ["#{self.class.table_name}.#{self.class.primary_key} <> ?", id]
      )
    end
    
    def leaves # :nodoc:
      descendants.scoped(
        :conditions => "NOT EXISTS (SELECT * FROM #{self.class.table_name} #{self.class.table_name}_children WHERE #{self.class.nestable_options[:parent_column]} = #{self.class.table_name}.#{self.class.primary_key})"
      )
    end
    
    def level # :nodoc:
      level_column_value
    end
    
    # Returns the value of a node's <tt>:level_column</tt>
    def level_column_value
      level_column = self.class.nestable_options[:level_column]
      level_column.to_s == 'level' ? self[level_column] : send(level_column)
    end
    
    # Returns the value of a node's <tt>:path_column</tt>
    def path_column_value
      send(self.class.nestable_options[:path_column])
    end
    
    # Returns true if a node's <tt>:path_column</tt> value was changed, false otherwise
    def path_column_value_changed?
      send("#{self.class.nestable_options[:path_column]}_changed?")
    end
    
    # Returns the same thing as <tt>path_column_value_changed?</tt> but its value is not cleared after saving
    def path_column_value_updated?
      @path_column_value_updated
    end
    
    # Returns the old value of a node's <tt>:path_column</tt> if it was was changed
    def path_column_value_was
      send("#{self.class.nestable_options[:path_column]}_was")
    end
    
    def reload_with_nestable_path(*args) # :nodoc:
      @path_column_value_updated = nil
      reload_without_nestable_path(*args)
    end
    
    def self_and_descendants # :nodoc:
      nestable_scope.scoped(
        :conditions => [
          "#{self.class.table_name}.#{self.class.nestable_options[:path_column]} LIKE ? OR #{self.class.table_name}.#{self.class.primary_key} = ?", 
          "#{path_column_value}#{segment_column_value}#{self.class.nestable_options[:segment_delimiter]}%", 
          id
        ]
      )
    end
    
    # Returns the value of a node's <tt>:segment_column</tt>
    def segment_column_value
      send(self.class.nestable_options[:segment_column])
    end
    
    # Returns true if a node's <tt>:segment_column</tt> value was changed, false otherwise
    def segment_column_value_changed?
      send("#{self.class.nestable_options[:segment_column]}_changed?")
    end
    
    # Returns the old value of a node's <tt>:segment_column</tt> if it was was changed
    def segment_column_value_was
      send("#{self.class.nestable_options[:segment_column]}_was")
    end
    
    protected
      
      def set_path_column_value # :nodoc:
        nestable_path = ''
        unless parent.nil?
          nestable_path << parent.path_column_value
          nestable_path << parent.segment_column_value.to_s
          nestable_path << self.class.nestable_options[:segment_delimiter]
        end
        if new_record? || nestable_path != path_column_value
          @path_column_value_updated = true
          send("#{self.class.nestable_options[:path_column]}=".to_sym, nestable_path)
          send("#{self.class.nestable_options[:level_column]}=".to_sym, nestable_path.scan(self.class.nestable_options[:segment_delimiter]).size)
        end
      end
      
      def update_child_path_column_values # :nodoc:
        if path_column_value_updated?
          children.update_all [
            "#{self.class.nestable_options[:path_column]} = ?, #{self.class.nestable_options[:level_column]} = ?",
            path_column_value + self.class.nestable_options[:segment_delimiter] + segment_column_value.to_s,
            level_column_value + 1
          ]
          children.each(&:update_child_path_column_values)
        end
      end
      
  end
end