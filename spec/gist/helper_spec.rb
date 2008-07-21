require File.dirname(__FILE__) + '/spec_helper'

describe GitHub::Helper do
  include SetupMethods

  def self.helper(name, &block)
    HelperRunner.new(self, name).run(&block)
  end

  before(:each) do
    @helper = GitHub::Helper.new
  end

  helper :homepage do
    it "should return the gist homepage" do
      @helper.homepage.should == "http://gist.github.com"
    end
  end

  helper :homepage_for do
    it "should return the gist homepage for the given user" do
      @helper.homepage_for("kballard").should == "http://gist.github.com/kballard"
      @helper.homepage_for("defunkt").should == "http://gist.github.com/defunkt"
    end
  end
end
