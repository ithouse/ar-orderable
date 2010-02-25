require File.dirname(__FILE__) + '/spec_helper'

describe Lolita::Orderable do
  it "should order correctly" do
    5.times{|i| Category.create(:name => "Cat #{i+1}")}
    Category.count.should == 5
    Category.first.order_nr.should == 1
    Category.last.order_nr.should == 5
    c = Category.first
    c.update_attribute(:order_nr, 4)
    Category.find_by_name("Cat 1").order_nr.should == 4
    Category.first.name.should == "Cat 2"
    Category.find_by_order_nr(3).move_to 1
    Category.find_by_name("Cat 4").order_nr.should == 1
  end
end