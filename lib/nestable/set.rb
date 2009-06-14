module Nestable
  module Set
    
    include Nestable::Tree
    
    def self.included(base)
      Nestable::Tree.included(base)
    end
    
    def self.process_options!(options)
      { :left_column => :lft, :right_column => :rgt }.merge(Nestable::Tree.process_options!(options))
    end
    
    def ancestors
    end
    
    def descendants
    end
    
    def leaves
    end
    
    def root
    end
    
    def siblings
    end
    
  end
end