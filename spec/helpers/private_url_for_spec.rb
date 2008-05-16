require File.dirname(File.dirname(__FILE__)) + '/spec_helper'

describe "The private_url_for helper" do
  before(:each) do
    @helper = GitHub::Helper.new
  end

  it "should return git@github.com:wycats/merb-core.git" do
    @helper.should_receive(:url_for).with(:origin).and_return("git://github.com/user/merb-core.git")
    @helper.private_url_for("wycats").should == "git@github.com:wycats/merb-core.git"
  end
end
