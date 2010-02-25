require 'rubygems'
require 'spec'
require 'active_support'
require 'active_record'
require File.dirname(__FILE__)+'/../init.rb'

ActiveRecord::Base.establish_connection({ :database => ":memory:", :adapter => 'sqlite3', :timeout => 500 })

ActiveRecord::Schema.define do
  create_table :categories, :force => true do |t|
    t.string :name
    t.integer :order_nr
  end
end

class Category < ActiveRecord::Base
  acts_as_orderable
end