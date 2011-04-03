require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github home" do
  include CommandHelper
  
  specify "home should open the project home page" do
    running :home do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/user/project")
    end
  end

  specify "home defunkt should open the home page of defunkt's fork" do
    running :home, "defunkt" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project")
    end
  end
end