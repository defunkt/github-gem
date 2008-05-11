require File.dirname(__FILE__) + '/../spec_helper'

describe "The user_and_repo_from helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should parse a git:// url" do
    @helper.user_and_repo_from("git://github.com/defunkt/github.git").should == ["defunkt", "github.git"]
  end

  it "should parse a ssh-based url" do
    @helper.user_and_repo_from("git@github.com:mojombo/god.git").should == ["mojombo", "god.git"]
  end

  it "should return nothing for other urls" do
    @helper.user_and_repo_from("home:path/to/repo.git").should == ['', '']
  end

  it "should return nothing for invalid git:// urls" do
    @helper.user_and_repo_from("git://github.com/foo").should == ['', '']
  end

  it "should return nothing for invalid ssh-based urls" do
    @helper.user_and_repo_from("git@github.com:kballard").should == ['', '']
  end
end
