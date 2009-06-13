require 'test/unit'
require 'rubygems'
gem 'activerecord', '>= 2.0.0'
require 'active_record'

require File.dirname(__FILE__) + '/../lib/nestable'
Dir[File.dirname(__FILE__) + '/../lib/nestable/*.rb'].each { |theory| require theory }

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def create_tables
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :categories do |t|
        t.integer  :site_id
        t.integer  :parent_id
      end
      
      create_table :pages do |t|
        t.integer  :site_id
        t.integer  :parent_id
        t.integer  :lft
        t.integer  :rgt
      end
    end
  end
end

# The table needs to exist before defining the class
create_tables

Test::Unit::TestCase.class_eval do
  def setup
    ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
    create_tables
  end
end