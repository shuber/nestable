module Nestable
  
  METHODS = %w(ancestors children descendants is_ancestor_of? is_descendant_of? is_sibling_of? is_root? leaves level parent root roots self_and_ancestors self_and_children self_and_descendants self_and_siblings siblings)
  
  def nestable(options = {})
    theory = "Nestable::#{(options[:theory] ||= :tree).to_s.classify}".constantize
    missing_methods = METHODS.reject { |method| theory.method_defined?(method) }
    raise NotImplementedError.new("#{theory} must implement the following Nestable methods: #{missing_methods.sort.to_sentence}") unless missing_methods.empty?
    cattr_accessor :nestable_options
    self.nestable_options = theory.process_options!({ :class => self }.merge(options))
    include theory
  end
  
end

ActiveRecord::Base.extend Nestable