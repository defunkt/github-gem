require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github admin" do
  include CommandHelper
  
  specify "admin should open the project admin page" do
    running :admin do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/user/project/admin")
    end
  end

  specify "admin drnic should open the home page of drnic's fork" do
    running :admin, "drnic" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/drnic/project/admin")
    end
  end
end