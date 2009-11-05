require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.dirname(__FILE__) + '/command_helper'

describe "github network" do
  include CommandHelper
  
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