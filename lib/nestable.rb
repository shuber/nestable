module Nestable
  
  # Adds nesting support to the current class.
  #
  # Accepts an optional argument <tt>:theory</tt> along with any other options related with that theory.
  # Take a look at a theory's documentation for a list of its related options.
  #
  # Example:
  #
  #   class Category < ActiveRecord::Base
  #     nestable :theory => :set, :scope => :site_id
  #   end
  #
  # The default <tt>:theory</tt> is <tt>:tree</tt>
  def nestable(options = {})
    options = { :class => self }.merge(options)
    theory = "Nestable::#{(options[:theory] ||= :tree).to_s.classify}".constantize
    missing_methods = Nestable::Interface.instance_methods.reject { |method| theory.method_defined?(method) }
    raise NotImplementedError.new("#{theory} must implement the following Nestable methods: #{missing_methods.sort.to_sentence}") unless missing_methods.empty?
    cattr_accessor :nestable_options
    self.nestable_options = theory.respond_to?(:process_options!) ? theory.process_options!(options) : options
    include theory
  end
  
end

ActiveRecord::Base.extend Nestable