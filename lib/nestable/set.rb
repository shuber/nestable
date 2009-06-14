module Nestable
  module Set
    
    include Nestable::Tree
    
    def self.included(base)
      Nestable::Tree.included(base)
    end
    
    def self.process_options!(options)
      { :left_column => :lft, :right_column => :rgt }.merge(Nestable::Tree.process_options!(options))
    end
    
  end
end