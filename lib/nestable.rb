module Nestable
  
  def nestable(options = {})
    cattr_accessor :nestable_options
    theory = "Nestable::#{(options[:theory] ||= :tree).to_s.classify}".constantize
    self.nestable_options = theory.process_options!({ :class => self }.merge(options))
    include Interface, theory
  end
  
  module Interface
    %w(
      ancestors
      children
      descendants
      is_ancestor_of
      is_descendant_of
      is_sibling_of
      is_root?
      leaves
      level
      parent
      root
      roots
      self_and_ancestors
      self_and_children
      self_and_descendants
      self_and_siblings
      siblings
    ).each do |method|
      define_method method do |*args|
        raise NotImplementedError.new("#{method} must be implemented by the Nestable::#{self.class.nestable_options[:theory].to_s.classify} module")
      end
    end
  end
  
end

ActiveRecord::Base.extend Nestable