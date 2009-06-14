require 'test_helper'

module Nestable
  module TheoryWithValidation
    def self.process_options!(options)
      options
    end
    
    Nestable::METHODS.each { |m| define_method(m) {} }
  end
  
  module TheoryWithoutValidation
    Nestable::METHODS.each { |m| define_method(m) {} }
  end
  
  module TheoryWithoutMethod
  end
end

class NestableTest < Test::Unit::TestCase
  
  def setup
    setup_tables
  end
  
  def test_should_add_a_nestable_method_to_active_record
    assert ActiveRecord::Base.respond_to?(:nestable)
  end
  
  def test_should_not_raise_a_name_error_if_theory_exists
    ActiveRecord::Base.nestable
  end
  
  def test_should_raise_a_name_error_if_theory_does_not_exist
    assert_raises(NameError) { ActiveRecord::Base.nestable :theory => 'invalid' }
  end
  
  def test_should_raise_a_no_method_error_if_theory_does_not_have_a_process_options_method
    assert_raises(NoMethodError) { ActiveRecord::Base.nestable :theory => 'theory_without_validation' }
  end
  
  def test_should_add_a_cattr_accessor_for_nestable_options
    assert !ActiveRecord::Base.respond_to?(:nestable_options)
    ActiveRecord::Base.nestable
    assert ActiveRecord::Base.respond_to?(:nestable_options)
  end
  
  def test_should_include_theory
    assert !ActiveRecord::Base.include?(Nestable::TheoryWithValidation)
    ActiveRecord::Base.nestable :theory => 'theory_with_validation'
    assert ActiveRecord::Base.include?(Nestable::TheoryWithValidation)
  end
  
  def test_should_add_the_class_to_nestable_options
    ActiveRecord::Base.nestable
    assert_equal ActiveRecord::Base, ActiveRecord::Base.nestable_options[:class]
  end
  
  def test_should_raise_not_implemented_error_if_theory_is_missing_nestable_interface_methods
    assert_raises NotImplementedError do
      ActiveRecord::Base.nestable :theory => :theory_without_method
    end
  end
  
end