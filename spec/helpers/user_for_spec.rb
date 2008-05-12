require File.dirname(File.dirname(__FILE__)) + '/spec_helper'

describe "The user_for helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should return defunkt" do
    @helper.should_receive(:url_for).with("origin").and_return("git@github.com:defunkt/project.git")
    @helper.user_for("origin").should == "defunkt"
  end
end
