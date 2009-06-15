module Nestable
  # Pros: 
  #
  # * Quick reads - you can fetch a node and all of its descendants in a single query
  #
  # Cons: 
  #
  # * Slow writes - left and right boundaries must be re-calculated for all associated nodes when a record is added or removed
  #
  # Options:
  #
  #   :class_name     -  The class name to use for the parent and children associations. Defaults to the name of the current class.
  #   :dependent      -  The dependent option for the children association. Defaults to :destroy.
  #   :left_column    -  The name of the column that references a node's left boundary. Defaults to :left.
  #   :order          -  The default order to use when collecting children, descendants, siblings, etc. Defaults to nil.
  #   :parent_column  -  The name of the foreign key that references a node's parent. Defaults to :parent_id.
  #   :right_column   -  The name of the column that references a node's right boundary. Defaults to :right.
  #   :scope          -  A field or an array of fields to scope trees to. Defaults to an empty array.
  module Set
    
    include Nestable::Tree
    
    def self.included(base) # :nodoc:
      Nestable::Tree.included(base)
    end
    
    def self.process_options!(options) # :nodoc:
      { :left_column => :lft, :right_column => :rgt }.merge(Nestable::Tree.process_options!(options))
    end
    
    def ancestors # :nodoc:
    end
    
    def descendants # :nodoc:
    end
    
    def leaves # :nodoc:
    end
    
    def root # :nodoc:
    end
    
    def siblings # :nodoc:
    end
    
  end
end