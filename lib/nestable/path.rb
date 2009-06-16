module Nestable
  # Pros:
  #
  # * Quick inserts - it only needs to calculate the <tt>:path_column</tt> on the current node by looking up its parent's <tt>:path_column</tt> and <tt>:segment_column</tt>
  # * Quick reads - it can fetch a node and all of its descendants in a single query
  #
  # Cons:
  #
  # * Slow updates - the <tt>:path_column</tt> must be re-calculated and saved one by one for every descendant node (if it was changed)
  #
  # Options:
  #
  #   :class_name         -  The class name to use for the parent and children associations. Defaults to the name of the current class.
  #   :dependent          -  The dependent option for the children association. Defaults to :destroy.
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
      options = { :path_column => :path, :segment_column => :id, :segment_delimiter => '/' }.merge(options)
      options[:order] ||= [options[:path_column], options[:segment_column]]
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
      nestable_path = path_column_value_changed? ? path_column_value_was : path_column_value
      nestable_segment = segment_column_value_changed? ? segment_column_value_was : segment_column_value
      nestable_scope.scoped(
        :conditions => [
          "#{self.class.table_name}.#{self.class.nestable_options[:path_column]} LIKE ? OR #{self.class.table_name}.#{self.class.primary_key} = ?", 
          "#{nestable_path}#{nestable_segment}#{self.class.nestable_options[:segment_delimiter]}%", 
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
        @path_column_value_updated = (nestable_path != path_column_value && !new_record?)
        send("#{self.class.nestable_options[:path_column]}=".to_sym, nestable_path)
      end
      
      def update_child_path_column_values # :nodoc:
        # TODO: figure out a compatible way to UPDATE with ORDER in sql for all adapters so that we can do this in one query
        children.each(&:save) if path_column_value_updated?
      end
      
  end
end