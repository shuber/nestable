require 'test_helper'

class Nest < ActiveRecord::Base
end

module Nestable
  module TheoryWithValidation
    def self.process_options!(options)
      options
    end
    
    Nestable::Interface.instance_methods.each { |m| define_method(m) {} }
  end
  
  module TheoryWithoutValidation
    Nestable::Interface.instance_methods.each { |m| define_method(m) {} }
  end
  
  module TheoryWithoutMethod
  end
end

class NestableTest < Test::Unit::TestCase
  
  def setup
    setup_tables
  end
  
  def test_should_add_a_nestable_method_to_active_record
    assert Nest.respond_to?(:nestable)
  end
  
  def test_should_not_raise_a_name_error_if_theory_exists
    Nest.nestable
  end
  
  def test_should_raise_a_name_error_if_theory_does_not_exist
    assert_raises(NameError) { Nest.nestable :theory => 'invalid' }
  end
  
  def test_should_add_a_cattr_accessor_for_nestable_options
    assert !Nest.respond_to?(:nestable_options)
    Nest.nestable
    assert Nest.respond_to?(:nestable_options)
  end
  
  def test_should_include_theory
    assert !Nest.include?(Nestable::TheoryWithValidation)
    Nest.nestable :theory => 'theory_with_validation'
    assert Nest.include?(Nestable::TheoryWithValidation)
  end
  
  def test_should_add_the_class_to_nestable_options
    Nest.nestable
    assert_equal Nest, Nest.nestable_options[:class]
  end
  
  def test_should_raise_not_implemented_error_if_theory_is_missing_nestable_interface_methods
    assert_raises NotImplementedError do
      Nest.nestable :theory => :theory_without_method
    end
  end
  
end