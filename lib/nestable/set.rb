module Nestable
  module Set
    
    include Nestable::Tree
    
    def self.included(base) #:nodoc:
      Nestable::Tree.included(base)
    end
    
    def self.process_options!(options) #:nodoc:
      { :left_column => :lft, :right_column => :rgt }.merge(Nestable::Tree.process_options!(options))
    end
    
    def ancestors #:nodoc:
    end
    
    def descendants #:nodoc:
    end
    
    def leaves #:nodoc:
    end
    
    def root #:nodoc:
    end
    
    def siblings #:nodoc:
    end
    
  end
end