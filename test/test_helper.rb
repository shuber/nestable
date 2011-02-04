require 'rubygems'
require 'test/unit'
gem 'activerecord', '>= 3.0.0'
require 'active_record'

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.dirname(__FILE__))
require 'nestable'

ActiveRecord::Base.establish_connection :adapter => 'sqlite3', :database => ':memory:'

def setup_tables
  ActiveRecord::Base.connection.tables.each { |table| ActiveRecord::Base.connection.drop_table(table) }
  silence_stream(STDOUT) do
    ActiveRecord::Schema.define(:version => 1) do
      create_table :categories do |t|
        t.integer  :site_id
        t.integer  :parent_id
        t.integer  :level # optional
      end

      create_table :nests do |t|
        t.integer  :site_id
        t.integer  :parent_id
      end

      create_table :pages do |t|
        t.string   :type
        t.integer  :site_id
        t.integer  :parent_id
        t.string   :path
        t.integer  :level
      end
    end
  end
end

# The tables need to exist before defining the models
setup_tables