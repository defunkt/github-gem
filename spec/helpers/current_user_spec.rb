require File.dirname(__FILE__) + '/../spec_helper'

describe "The current_user helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should return hacker" do
    @helper.should_receive(:url_for).with(:origin).and_return("git://github.com/hacker/project.git")
    @helper.current_user.should == "hacker"
  end
end
