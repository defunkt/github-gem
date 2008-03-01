require File.dirname(__FILE__) + '/../spec_helper'

describe "The user_and_repo_from helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should return defunkt and github.git" do
    @helper.user_and_repo_from("git://github.com/defunkt/github.git").should == ["defunkt", "github.git"]
  end

  it "should return mojombo and god.git" do
    @helper.user_and_repo_from("git@github.com:mojombo/god.git").should == ["mojombo", "god.git"]
  end
end
