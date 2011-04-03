require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github fork" do
  include CommandHelper
  
  specify "fork should print out help" do
    running :fork do
      @helper.should_receive(:remotes).and_return({})
      @command.should_receive(:die).with("Specify a user/project to fork, or run from within a repo").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end
  
  specify "fork this repo should create github fork and replace origin remote" do
    running :fork do
      setup_github_token
      setup_url_for "origin", "defunkt", "github-gem"
      setup_remote "origin", :user => "defunkt", :project => "github-gem"
      setup_user_and_branch
      @command.should_receive(:sh).with("curl -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' https://github.com/defunkt/github-gem/fork")
      @command.should_receive(:git).with("config remote.origin.url git@github.com:drnic/github-gem.git")
      stdout.should == "defunkt/github-gem forked\n"
    end
  end

  specify "fork a user/project repo" do
    running :fork, "defunkt/github-gem" do
      setup_github_token
      @command.should_receive(:sh).with("curl -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' https://github.com/defunkt/github-gem/fork")
      @command.should_receive(:git_exec).with("clone git@github.com:drnic/github-gem.git")
      stdout.should == "Giving GitHub a moment to create the fork...\n"
    end
  end

  specify "fork a user project repo" do
    running :fork, "defunkt", "github-gem" do
      setup_github_token
      @command.should_receive("sh").with("curl -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' https://github.com/defunkt/github-gem/fork")
      @command.should_receive(:git_exec).with("clone git@github.com:drnic/github-gem.git")
      stdout.should == "Giving GitHub a moment to create the fork...\n"
    end
  end
end
