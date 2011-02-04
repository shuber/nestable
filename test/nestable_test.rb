require 'test_helper'

module Nestable::Strategy::Mock; end
module Nestable::Strategy::Mock2; end
module Nestable::Strategy::Mock3; end

class Nest < ActiveRecord::Base
end

class NestableTest < Test::Unit::TestCase
  def setup
    setup_tables
  end

  def test_should_include_interface
    Nest.nestable
    assert Nest.include?(Nestable::Interface)
  end

  def test_should_allow_constant_strategies
    assert !Nest.include?(Nestable::Strategy::Mock)
    Nest.nestable :strategy => Nestable::Strategy::Mock
    assert Nest.include?(Nestable::Strategy::Mock)
  end

  def test_should_allow_symbol_strategies
    assert !Nest.include?(Nestable::Strategy::Mock2)
    Nest.nestable :strategy => :mock2
    assert Nest.include?(Nestable::Strategy::Mock2)
  end

  def test_should_allow_string_strategies
    assert !Nest.include?(Nestable::Strategy::Mock3)
    Nest.nestable :strategy => 'Nestable::Strategy::Mock3'
    assert Nest.include?(Nestable::Strategy::Mock3)
  end

  def test_should_raise_name_error_if_strategy_does_not_exist
    assert_raises(NameError) { Nest.nestable :strategy => 'invalid' }
  end
end