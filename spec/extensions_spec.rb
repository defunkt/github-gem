require File.dirname(__FILE__) + "/spec_helper"

describe "When calling #try" do
  specify "objects should return themselves" do
    obj = 1; obj.try.should equal(obj)
    obj = "foo"; obj.try.should equal(obj)
    obj = { :foo => "bar" }; obj.try.should equal(obj)
  end

  specify "objects should behave as if #try wasn't called" do
    "foo".try.size.should == 3
    { :foo => :bar }.try.fetch(:foo).should == :bar
  end

  specify "nil should return the singleton NilClass::NilProxy" do
    nil.try.should equal(NilClass::NilProxy)
  end

  specify "nil should ignore any calls made past #try" do
    nil.try.size.should == nil
    nil.try.sdlfj.should == nil
  end

  specify "classes should respond just like objects" do
    String.try.should equal(String)
  end
end
