require File.dirname(File.dirname(__FILE__)) + '/spec_helper'

describe "The repo_for helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should return mephisto.git" do
    @helper.should_receive(:url_for).with("mojombo").and_return("git@github.com:mojombo/mephisto.git")
    @helper.repo_for("mojombo").should == "mephisto.git"
  end
end
