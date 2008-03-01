require File.dirname(__FILE__) + '/../spec_helper'

describe "The project helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should return project-awesome" do
    @helper.should_receive(:url_for).with(:origin).and_return("git://github.com/user/project-awesome.git")
    @helper.project.should == "project-awesome"
  end
end
