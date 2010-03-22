require 'rubygems'
require 'spec'
require 'active_support'
require 'active_record'
require File.dirname(__FILE__)+'/../init.rb'
ActiveRecord::Base.logger = Logger.new(File.open("#{File.dirname(__FILE__)}/database.log", 'w+'))
ActiveRecord::Base.establish_connection({ :database => ":memory:", :adapter => 'sqlite3', :timeout => 500 })

ActiveRecord::Schema.define do
  create_table :categories, :force => true do |t|
    t.string :name
    t.integer :cat_type_id
    t.integer :order_nr
  end
  create_table :cat_types, :force => true do |t|
    t.string :name
  end
end

class CatType < ActiveRecord::Base
  has_many :categories, :dependent => :destroy
end

class Category < ActiveRecord::Base
  belongs_to :cat_type
  acts_as_orderable :scope => :cat_type_id
end

Spec::Runner.configure do |config|
  config.before(:each) do
    Category.destroy_all
    CatType.destroy_all
  end
end