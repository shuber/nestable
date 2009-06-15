module Nestable
  # The standard interface for all nestable theories. Every nestable ActiveRecord 
  # instance will respond to these methods reguardless of which theory was used.
  module Interface
    
    def ancestor_ids
    end
    
    def ancestors
    end
    
    def children
    end
    
    def children_ids
    end
    
    def descendant_ids
    end
    
    def descendants
    end
    
    def is_ancestor_of?(node)
    end
    
    def is_descendant_of?(node)
    end
    
    def is_sibling_of?(node)
    end
    
    def is_root?
    end
    
    def leave_ids
    end
    
    def leaves
    end
    
    def level
    end
    
    def parent
    end
    
    def root
    end
    
    def root_ids
    end
    
    def roots
    end
    
    def self_and_ancestor_ids
    end
    
    def self_and_ancestors
    end
    
    def self_and_children
    end
    
    def self_and_children_ids
    end
    
    def self_and_descendant_ids
    end
    
    def self_and_descendants
    end
    
    def self_and_sibling_ids
    end
    
    def self_and_siblings
    end
    
    def sibling_ids
    end
    
    def siblings
    end
    
  end
end