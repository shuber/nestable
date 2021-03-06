require 'interface'

# Adds nesting functionality to ActiveRecord objects with various strategies like: tree, set, path, etc.
module Nestable
  autoload :Interface, 'nestable/interface'
  autoload :Strategy,  'nestable/strategy'
  autoload :Version,   'nestable/version'

  def self.extended(base) # :nodoc:
    base.class_eval do
      cattr_accessor :nestable_options
      self.nestable_options = { :strategy => :tree }
    end
  end

  # Adds nesting functionality to the current class.
  #
  # Accepts an optional argument <tt>:strategy</tt> along with any other options related with that strategy.
  # Take a look at each strategy's documentation for a list of its related options.
  #
  # Example:
  #
  #   class Category < ActiveRecord::Base
  #     nestable :strategy => :path, :scope => :store_id
  #   end
  #
  # The default <tt>:strategy</tt> is <tt>:tree</tt>
  def nestable(options = {})
    nestable_options.merge!(options)
    nestable_options[:strategy] = case nestable_options[:strategy]
      when String then nestable_options[:strategy].constantize
      when Symbol then Strategy.const_get(nestable_options[:strategy].to_s.classify)
      else nestable_options[:strategy]
    end
    implement Interface and include nestable_options[:strategy]
  end
end

ActiveRecord::Base.extend Nestable