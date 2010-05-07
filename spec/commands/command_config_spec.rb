require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.dirname(__FILE__) + '/command_helper'

describe "github config" do
  include CommandHelper
  
  specify "config takes [user token] if provided" do
    running :config, "drnic", "TOKEN" do
      @command.should_receive(:git, "--global github.user drnic")
      @command.should_receive(:git, "--global github.token TOKEN")
      stdout.should == "Configured with github.user drnic\n"
    end
  end
  specify "config should ask for user + token if not provided" do
    running :config do
      @command.should_receive()
    end
  end
  specify "test-config commands should request github config if not available" do
    running :fork do
      setup_github_token :user => nil, :token => nil
      @command.should_receive(:config)
    end
  end
  
end