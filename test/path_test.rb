require 'test_helper'

class Page < ActiveRecord::Base
  nestable :theory => :path, :scope => :site_id
end

class PathTest < Test::Unit::TestCase
  
  def setup
    setup_tables
    @root = Page.create!
    @root_2 = Page.create!
    @child = Page.create! :parent_id => @root.id
    @child_2 = Page.create! :parent_id => @root.id
    @child_3 = Page.create! :parent_id => @root_2.id
    @sub_child = Page.create! :parent_id => @child.id
    [@root, @root_2, @child, @child_2, @child_3, @sub_child].each(&:reload)
  end
  
  def test_descendants
    assert_equal [@child, @sub_child, @child_2], @root.descendants
    assert_equal [@child_3], @root_2.descendants
    assert_equal [@sub_child], @child.descendants
    assert_equal [], @child_2.descendants
  end
  
  def test_leaves
    assert_equal [@sub_child, @child_2], @root.leaves
    assert_equal [@child_3], @root_2.leaves
    assert_equal [@sub_child], @child.leaves
    assert_equal [], @child_2.leaves
  end
  
  def test_path_column_value
    assert_equal @root.path, @root.path_column_value
    assert_equal @child.path, @child.path_column_value
    assert_equal @sub_child.path, @sub_child.path_column_value
  end
  
  def test_path_column_value_updated?
    assert !@sub_child.path_column_value_updated?
    @sub_child.path = 'testing'
    assert @sub_child.path_column_value_updated?
  end
  
  def test_reload_with_nestable_path
    assert !@child.path_column_value_updated?
    @child.update_attribute(:parent_id, @root_2.id)
    assert @child.path_column_value_updated?
    assert @child.reload
    assert !@child.path_column_value_updated?
  end
  
  def test_self_and_descendants
    assert_equal [@root, @child, @sub_child, @child_2], @root.self_and_descendants
    assert_equal [@root_2, @child_3], @root_2.self_and_descendants
    assert_equal [@child_2], @child_2.self_and_descendants
  end
  
  def test_segment_column_value
    assert_equal @root.id, @root.segment_column_value
    assert_equal @child.id, @child.segment_column_value
    assert_equal @sub_child.id, @sub_child.segment_column_value
  end
  
  def test_segment_column_value_updated?
    assert !@sub_child.segment_column_value_updated?
    @sub_child.id = 99
    assert @sub_child.segment_column_value_updated?
  end
  
  def test_set_path_column_value
    assert_equal '', @root.path
    @sub_child.parent_id = @child_2.id
    @sub_child.save
    assert_equal @child_2.path + @child_2.id.to_s + '/', @sub_child.path
  end
  
  def test_update_child_path_column_values
    old_child_path = @child.path
    old_sub_child_path = @sub_child.path
    @child.update_attribute(:parent_id, @root_2.id)
    [@child, @sub_child].each(&:reload)
    assert_not_equal old_child_path, @child.path
    assert_not_equal old_sub_child_path, @sub_child.path
  end
  
end