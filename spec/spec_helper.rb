require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rails'
require 'active_record'
require 'rspec'
require 'logger'
require 'ruby-debug'
require 'ar-orderable'
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
  after_save :do_background_task
  after_save :resave_record
  attr_accessor :background_task, :must_resave

  private

  def do_background_task
    self.background_task = :done
  end
  
  def resave_record
    if @must_resave
      @must_resave = false
      self.save!
    end
  end
end

RSpec.configure do |config|
  config.before(:each) do
    Category.destroy_all
    CatType.destroy_all
  end
end
