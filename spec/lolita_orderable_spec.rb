require File.dirname(__FILE__) + '/spec_helper'

describe Lolita::Orderable do
  it "should order simple categories correctly" do
    5.times{|i| Category.create(:name => "Cat #{i+1}")}
    Category.count.should == 5
    Category.first.order_nr.should == 1
    Category.last.order_nr.should == 5
    c = Category.first
    c.update_attribute(:order_nr, 4)
    Category.find_by_name("Cat 1").order_nr.should == 4
    Category.first.name.should == "Cat 2"
    c = Category.first
    Category.find_by_name("Cat 4").move_to 1
    Category.find_by_name("Cat 4").order_nr.should == 1
    Category.find(c.id).order_nr.should == 2
  end

  it "should order categories correct by scope" do
    cat_types = [
      CatType.create(:name => "Type 1"),
      CatType.create(:name => "Type 2")
    ]

    5.times{|i| Category.create(:name => "Cat #{i+1}", :cat_type => cat_types.first)}
    5.times{|i| Category.create(:name => "Cat #{i+6}", :cat_type => cat_types.last)}

    Category.find_by_name("Cat 9").move_to 1
    Category.find_by_name("Cat 9").order_nr.should == 1
    Category.find_by_name("Cat 6").order_nr.should == 2
    Category.find_by_name("Cat 7").order_nr.should == 3
    Category.find_by_name("Cat 8").order_nr.should == 4
    Category.find_by_name("Cat 10").order_nr.should == 5
    
    Category.find_by_name("Cat 7").move_to 5

    Category.find_by_name("Cat 9").order_nr.should == 1
    Category.find_by_name("Cat 6").order_nr.should == 2
    Category.find_by_name("Cat 8").order_nr.should == 3
    Category.find_by_name("Cat 10").order_nr.should == 4
    Category.find_by_name("Cat 7").order_nr.should == 5

    Category.find_by_name("Cat 7").move_to 4

    Category.find_by_name("Cat 9").order_nr.should == 1
    Category.find_by_name("Cat 6").order_nr.should == 2
    Category.find_by_name("Cat 8").order_nr.should == 3
    Category.find_by_name("Cat 7").order_nr.should == 4
    Category.find_by_name("Cat 10").order_nr.should == 5

    Category.find_by_name("Cat 9").move_to 5

    Category.find_by_name("Cat 6").order_nr.should == 1
    Category.find_by_name("Cat 8").order_nr.should == 2
    Category.find_by_name("Cat 7").order_nr.should == 3
    Category.find_by_name("Cat 10").order_nr.should == 4
    Category.find_by_name("Cat 9").order_nr.should == 5

    Category.find_by_name("Cat 10").move_to 2

    Category.find_by_name("Cat 6").order_nr.should == 1
    Category.find_by_name("Cat 10").order_nr.should == 2
    Category.find_by_name("Cat 8").order_nr.should == 3
    Category.find_by_name("Cat 7").order_nr.should == 4
    Category.find_by_name("Cat 9").order_nr.should == 5
  end

  it "should create unordered list and order it with order_unordered method" do
    1.upto(4){|i| Category.create(:name => "Type #{i}")}
    @cat = Category.create(:name => "Type 0")
    Category.order_unordered
    @cat.order_nr.should_not == 1
    @cat.move_to 1
    @cat.reload
    @cat.order_nr.should == 1
  end
end