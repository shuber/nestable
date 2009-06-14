require 'test/unit'
require 'rubygems'
gem 'activerecord', '>= 2.0.0'
require 'active_record'

require File.dirname(__FILE__) + '/../lib/nestable'
%w(tree set).each { |theory| require File.dirname(__FILE__) + '/../lib/nestable/' + theory }

# ActiveRecord::Base.logger = Logger.new(STDOUT)
ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def setup_tables
  ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
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

# The tables need to exist before defining the models
setup_tables