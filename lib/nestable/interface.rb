module Nestable
  # The standard interface for all nestable theories. Every nestable ActiveRecord 
  # instance will respond to these methods regardless of which theory was used.
  module Interface
    
    # Returns an array containing the ids of a node's ancestors
    def ancestor_ids
    end
    
    # Returns an array containing a node's parents recursively
    def ancestors
    end
    
    # Returns an array containing a node's children
    def children
    end
    
    # Returns an array containing the ids of a node's children
    def children_ids
    end
    
    # Returns an array containing the ids of a node's descendants
    def descendant_ids
    end
    
    # Returns a flattened array containing all of a nodes's children recursively
    def descendants
    end
    
    # Moves all of a nodes descendants under its parent making them siblings
    def flatten!
    end
    
    # Returns true if a node is an ancestor of the specified node, false otherwise
    def is_ancestor_of?(node)
    end
    
    # Returns true if a node is a descendant of the specified node, false otherwise
    def is_descendant_of?(node)
    end
    
    # Returns true if a node is a sibling of the specified node, false otherwise
    def is_sibling_of?(node)
    end
    
    # Returns true if a node is a root, false otherwise
    def is_root?
    end
    
    # Returns an array containing the ids of a node's leaves
    def leave_ids
    end
    
    # Returns a flattened array containing descendants of a node that don't have children
    def leaves
    end
    
    # Returns the number of ancestors a node has
    def level
    end
    
    # Returns the parent of a node or nil if it doesn't have one
    def parent
    end
    
    # Returns the root of a node or itself if it is a root
    def root
    end
    
    # Returns an array containing the ids of a node's roots
    def root_ids
    end
    
    # Returns an array containing roots in the same scope as a node
    def roots
    end
    
    # Returns an array containing the ids of a node and its ancestors
    def self_and_ancestor_ids
    end
    
    # Returns an array containing a node and its ancestors
    def self_and_ancestors
    end
    
    # Returns an array containing a node and its children
    def self_and_children
    end
    
    # Returns an array containing the ids of a node and its children
    def self_and_children_ids
    end
    
    # Returns an array containing the ids of a node and its descendants
    def self_and_descendant_ids
    end
    
    # Returns a flattened array containing a node and its descendants
    def self_and_descendants
    end
    
    # Returns an array containing the ids of a node and its siblings
    def self_and_sibling_ids
    end
    
    # Returns an array containing a node and its siblings
    def self_and_siblings
    end
    
    # Returns an array containing the ids of a node's siblings
    def sibling_ids
    end
    
    # Returns an array containing records with the same parent as a node
    def siblings
    end
    
  end
end