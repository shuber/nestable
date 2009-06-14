module Nestable
  def nestable(options = {})
    theory = "Nestable::#{(options[:theory] ||= :tree).to_s.classify}".constantize
    missing_methods = Nestable::Interface.instance_methods.reject { |method| theory.method_defined?(method) }
    raise NotImplementedError.new("#{theory} must implement the following Nestable methods: #{missing_methods.sort.to_sentence}") unless missing_methods.empty?
    cattr_accessor :nestable_options
    self.nestable_options = theory.process_options!({ :class => self }.merge(options))
    include theory
  end
end

ActiveRecord::Base.extend Nestable