require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github network" do
  include CommandHelper
  
  specify "network list should show all users with a fork" do
    running :network, 'list' do
      setup_url_for 'origin', 'drnic'
      users = %w[defunkt drnic _why]
      @helper.should_receive(:network_members).with('drnic', {}).and_return(users)
      stdout.should == "defunkt\ndrnic\n_why\n"
    end
  end
  
  specify "network should open the network page for this repo" do
    running :network, 'web' do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/user/project/network")
    end
  end

  specify "network defunkt should open the network page for defunkt's fork" do
    running :network, 'web', "defunkt" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project/network")
    end
  end
  
end