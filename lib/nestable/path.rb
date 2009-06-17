module Nestable
  # Example table:
  #
  #   +------+---------+-------------+--------+---------+
  #   |  id  |  name   |  parent_id  |  path  |  level  |
  #   +------+---------+-------------+--------+---------+
  #   |  1   |  food   |     NULL    |        |    0    |
  #   |  2   |  fruit  |      1      |  1/    |    1    |
  #   |  3   |  sour   |      2      |  1/2/  |    2    |
  #   |  4   |  sweet  |      2      |  1/2/  |    2    |
  #   |  5   |  meat   |      1      |  1/    |    1    |
  #   |  6   |  beef   |      5      |  1/5/  |    2    |
  #   |  7   |  pork   |      5      |  1/5/  |    2    |
  #   +------+---------+-------------+--------+---------+
  #
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
  #   :level_column *     -  The name of the column that stores the number of ancestors a node has. Defaults to :level.
  #   :order              -  The default order to use when collecting children, descendants, siblings, etc. Defaults to nil.
  #   :parent_column *    -  The name of the foreign key that references the parent of a node. Defaults to :parent_id.
  #   :path_column *      -  The name of the column that references the ancestry path of a node. Defaults to :path.
  #   :scope              -  A field or an array of fields to scope trees to. Defaults to an empty array.
  #   :segment_column *   -  The name of the database column to use when calculating the path of a node. Defaults to :id.
  #   :segment_delimiter  -  The delimiter to use when separating segments and storing paths. Defaults to '/'
  #
  #   * Signifies a required field which must exist in your database
  #
  #     :level_column     -  integer
  #     :parent_column    -  integer
  #     :path_column      -  string
  #     :segment_column   -  string or integer
  module Path
    
    include Nestable::Tree
    
    def self.included(base) # :nodoc:
      Nestable::Tree.included(base)
      base.class_eval do
        before_save :set_path_column_value
        after_update :update_child_path_column_values
        alias_method_chain :reload, :nestable_path
        
        # define_method 'path=' do |value|
        #   @path_column_value_updated = true if value != path_column_value
        #   super value
        # end
        [:path, :segment].each do |column|
          define_method "#{base.nestable_options["#{column}_column".to_sym]}=" do |value|
            instance_variable_set("@#{column}_column_value_updated", true) if value != send("#{column}_column_value".to_sym)
            super value
          end
        end
      end
    end
    
    def self.process_options!(options) # :nodoc:
      options = { :level_column => :level, :path_column => :path, :segment_column => :id, :segment_delimiter => '/' }.merge(options)
      table_name = options[:class].table_name
      options[:order] = ["#{table_name}.#{options[:path_column]} || #{table_name}.#{options[:segment_column]} || '#{options[:segment_delimiter]}' || (#{table_name}.#{options[:level_column]}/100000000000)", Array(options[:order])].flatten.compact.join(', ')
      Nestable::Tree.process_options!(options)
    end
    
    def descendants # :nodoc:
      self_and_descendants.scoped(
        :conditions => ["#{self.class.table_name}.#{self.class.primary_key} <> ?", id]
      )
    end
    
    def leaves # :nodoc:
      descendants.leaves
    end
    
    # Returns the value of a node's <tt>:path_column</tt>
    def path_column_value
      send(self.class.nestable_options[:path_column])
    end
    
    # Returns <tt>path_column_value_changed?</tt> but the value is not set back to false until the node is reloaded
    def path_column_value_updated?
      !!@path_column_value_updated
    end
    
    def reload_with_nestable_path(*args) # :nodoc:
      @path_column_value_updated = nil
      @segment_column_value_updated = nil
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
    
    # Returns <tt>segment_column_value_changed?</tt> but the value is not set back to false until the node is reloaded
    def segment_column_value_updated?
      !!@segment_column_value_updated
    end
    
    protected
      
      def set_path_column_value # :nodoc:
        if new_record? || parent_column_value_changed?
          nestable_path = ''
          unless parent.nil?
            nestable_path << parent.path_column_value
            nestable_path << parent.segment_column_value.to_s
            nestable_path << self.class.nestable_options[:segment_delimiter]
          end
          send("#{self.class.nestable_options[:path_column]}=".to_sym, nestable_path)
        end
      end
      
      def update_child_path_column_values # :nodoc:
        if path_column_value_updated? || segment_column_value_updated?
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