require 'test_helper'

class Category < ActiveRecord::Base
  nestable :scope => :site_id, :level_column => :level
end

class TreeTest < Test::Unit::TestCase
  
  def setup
    setup_tables
    @root = Category.create!
    @root_2 = Category.create!
    @root_3 = Category.create! :site_id => 1
    @child = Category.create! :parent_id => @root.id
    @child_2 = Category.create! :parent_id => @root.id
    @child_3 = Category.create! :parent_id => @root_2.id
    @sub_child = Category.create! :parent_id => @child.id
  end
  
  def test_ancestors
    assert_equal [], @root.ancestors
    assert_equal [@root], @child.ancestors
    assert_equal [@child, @root], @sub_child.ancestors
  end
  
  def test_ancestor_ids
    assert_equal [], @root.ancestor_ids
    assert_equal [@root.id], @child.ancestor_ids
    assert_equal [@child.id, @root.id], @sub_child.ancestor_ids
  end
  
  def test_children
    assert_equal [@child, @child_2], @root.children
    assert_equal [@sub_child], @child.children
    assert_equal [], @sub_child.children
  end
  
  def test_children_ids
    assert_equal [@child.id, @child_2.id], @root.children_ids
    assert_equal [@sub_child.id], @child.children_ids
    assert_equal [], @sub_child.children_ids
  end
  
  def test_descendants
    assert_equal [@child, @sub_child, @child_2], @root.descendants
    assert_equal [@child_3], @root_2.descendants
    assert_equal [], @child_2.descendants
  end
  
  def test_descendant_ids
    assert_equal [@child.id, @sub_child.id, @child_2.id], @root.descendant_ids
    assert_equal [@child_3.id], @root_2.descendant_ids
    assert_equal [], @child_2.descendant_ids
  end
  
  def test_flatten!
    @root.flatten!
    assert_equal [@root_2, @child, @child_2, @sub_child], @root.siblings
  end
  
  def test_is_ancestor_of?
    assert @root.is_ancestor_of?(@child)
    assert @root.is_ancestor_of?(@sub_child)
    assert !@root.is_ancestor_of?(@child_3)
  end
  
  def test_is_descendant_of?
    assert @child.is_descendant_of?(@root)
    assert @sub_child.is_descendant_of?(@root)
    assert !@child_3.is_descendant_of?(@root)
  end
  
  def test_is_sibling_of?
    assert @child.is_sibling_of?(@child_2)
    assert @root.is_sibling_of?(@root_2)
    assert !@root.is_sibling_of?(@root_3)
    assert !@sub_child.is_sibling_of?(@child)
  end
  
  def test_is_root?
    assert @root.is_root?
    assert @root_2.is_root?
    assert !@child.is_root?
    assert !Category.new.is_root?
  end
  
  def test_leaves
    assert_equal [@sub_child, @child_2], @root.leaves
    assert_equal [@sub_child], @child.leaves
    assert_equal [], @child_2.leaves
  end
  
  def test_leave_ids
    assert_equal [@sub_child.id, @child_2.id], @root.leave_ids
    assert_equal [@sub_child.id], @child.leave_ids
    assert_equal [], @child_2.leave_ids
  end
  
  def test_level
    assert_equal 0, @root.level
    assert_equal 1, @child.level
    assert_equal 2, @sub_child.level
  end
  
  def test_parent
    assert_nil @root.parent
    assert_equal @root, @child.parent
    assert_equal @child, @sub_child.parent
  end
  
  def test_parent_column_value
    assert_nil @root.parent_column_value
    assert_equal @root.id, @child.parent_column_value
    assert_equal @child.id, @sub_child.parent_column_value
  end
  
  def test_parent_column_value_changed?
    assert !@root.parent_column_value_changed?
    @root.parent_id = 99
    assert @root.parent_column_value_changed?
  end
  
  def test_parent_column_value_was
    old_value = @child.parent_id
    @child.parent_id = 99
    assert_equal old_value, @child.parent_column_value_was
  end
  
  def test_root
    assert_equal @root, @root.root
    assert_equal @root, @child.root
    assert_equal @root, @sub_child.root
  end
  
  def test_roots
    assert_equal [@root, @root_2], @root.roots
    assert_equal [@root, @root_2], @child.roots
    assert_equal [@root_3], @root_3.roots
  end
  
  def test_root_ids
    assert_equal [@root.id, @root_2.id], @root.root_ids
    assert_equal [@root.id, @root_2.id], @child.root_ids
    assert_equal [@root_3.id], @root_3.root_ids
  end
  
  def test_self_and_ancestors
    assert_equal [@root], @root.self_and_ancestors
    assert_equal [@child, @root], @child.self_and_ancestors
    assert_equal [@sub_child, @child, @root], @sub_child.self_and_ancestors
  end
  
  def test_self_and_ancestor_ids
    assert_equal [@root.id], @root.self_and_ancestor_ids
    assert_equal [@child.id, @root.id], @child.self_and_ancestor_ids
    assert_equal [@sub_child.id, @child.id, @root.id], @sub_child.self_and_ancestor_ids
  end
  
  def test_self_and_children
    assert_equal [@root, @child, @child_2], @root.self_and_children
    assert_equal [@child, @sub_child], @child.self_and_children
    assert_equal [@sub_child], @sub_child.self_and_children
  end
  
  def test_self_and_children_ids
    assert_equal [@root.id, @child.id, @child_2.id], @root.self_and_children_ids
    assert_equal [@child.id, @sub_child.id], @child.self_and_children_ids
    assert_equal [@sub_child.id], @sub_child.self_and_children_ids
  end
  
  def test_self_and_descendants
    assert_equal [@root, @child, @sub_child, @child_2], @root.self_and_descendants
    assert_equal [@root_2, @child_3], @root_2.self_and_descendants
    assert_equal [@child_2], @child_2.self_and_descendants
  end
  
  def test_self_and_descendant_ids
    assert_equal [@root.id, @child.id, @sub_child.id, @child_2.id], @root.self_and_descendant_ids
    assert_equal [@root_2.id, @child_3.id], @root_2.self_and_descendant_ids
    assert_equal [@child_2.id], @child_2.self_and_descendant_ids
  end
  
  def test_self_and_siblings
    assert_equal [@root, @root_2], @root.self_and_siblings
    assert_equal [@root_3], @root_3.self_and_siblings
    assert_equal [@child, @child_2], @child.self_and_siblings
  end
  
  def test_self_and_sibling_ids
    assert_equal [@root.id, @root_2.id], @root.self_and_sibling_ids
    assert_equal [@root_3.id], @root_3.self_and_sibling_ids
    assert_equal [@child.id, @child_2.id], @child.self_and_sibling_ids
  end
  
  def test_siblings
    assert_equal [@root_2], @root.siblings
    assert_equal [], @root_3.siblings
    assert_equal [@child_2], @child.siblings
  end
  
  def test_sibling_ids
    assert_equal [@root_2.id], @root.sibling_ids
    assert_equal [], @root_3.sibling_ids
    assert_equal [@child_2.id], @child.sibling_ids
  end
  
  def test_ensure_parent_exists_in_nestable_scope
    @child.parent_id = @root_3.id
    assert !@child.valid?
    assert @child.errors.on(:parent_id)
  end
  
  def test_ensure_parent_column_does_not_reference_self_and_descendants
    @root.parent_id = @root.id
    assert !@root.valid?
    assert @root.errors.on(:parent_id)
    
    assert @child.is_descendant_of?(@root)
    @root.parent_id = @child.id
    assert !@root.valid?
    assert @root.errors.on(:parent_id)
  end
  
end