require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github pull-request" do
  include CommandHelper
  
  specify "pull-request should die with no args" do
    running :'pull-request' do
      setup_url_for
      @command.should_receive(:die).with("Specify a user for the pull request").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "pull-request user should track user if untracked" do
    running :'pull-request', "user" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :defunkt
      GitHub.should_receive(:invoke).with(:track, "user").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "pull-request user/branch should generate a pull request" do
    running :'pull-request', "user/branch" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :user
      @command.should_receive(:git_exec).with("request-pull user/branch origin")
    end
  end

  specify "pull-request user should generate a pull request with branch master" do
    running :'pull-request', "user" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :user
      @command.should_receive(:git_exec).with("request-pull user/master origin")
    end
  end

  specify "pull-request user branch should generate a pull request" do
    running:'pull-request', "user", "branch" do
      setup_url_for
      setup_remote :origin, :user => "kballard"
      setup_remote :user
      @command.should_receive(:git_exec).with("request-pull user/branch origin")
    end
  end
end