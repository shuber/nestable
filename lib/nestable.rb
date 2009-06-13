module Nestable
  def nestable(options = {})
    cattr_accessor :nestable_options
    theory = "Nestable::#{(options.delete(:theory) || :tree).to_s.classify}".constantize
    self.nestable_options = theory.validate_nestable_options({ :class => self }.merge(options))
    include theory
  end
end

ActiveRecord::Base.extend Nestable