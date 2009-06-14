require 'test_helper'

class Category < ActiveRecord::Base
  nestable :scope => :site_id
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
  
  def test_children
    assert_equal [@child, @child_2], @root.children
    assert_equal [@sub_child], @child.children
    assert_equal [], @sub_child.children
  end
  
  def test_descendants
    assert_equal [@child, @sub_child, @child_2], @root.descendants
    assert_equal [@child_3], @root_2.descendants
    assert_equal [], @child_2.descendants
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
  
  def test_self_and_ancestors
    assert_equal [@root], @root.self_and_ancestors
    assert_equal [@child, @root], @child.self_and_ancestors
    assert_equal [@sub_child, @child, @root], @sub_child.self_and_ancestors
  end
  
  def test_self_and_children
    assert_equal [@root, @child, @child_2], @root.self_and_children
    assert_equal [@child, @sub_child], @child.self_and_children
    assert_equal [@sub_child], @sub_child.self_and_children
  end
  
  def test_self_and_descendants
    assert_equal [@root, @child, @sub_child, @child_2], @root.self_and_descendants
    assert_equal [@root_2, @child_3], @root_2.self_and_descendants
    assert_equal [@child_2], @child_2.self_and_descendants
  end
  
  def test_self_and_siblings
    assert_equal [@root, @root_2], @root.self_and_siblings
    assert_equal [@root_3], @root_3.self_and_siblings
    assert_equal [@child, @child_2], @child.self_and_siblings
  end
  
  def test_siblings
    assert_equal [@root_2], @root.siblings
    assert_equal [], @root_3.siblings
    assert_equal [@child_2], @child.siblings
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