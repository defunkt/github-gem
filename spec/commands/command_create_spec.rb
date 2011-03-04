require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.dirname(__FILE__) + '/command_helper'

describe "github create" do
  include CommandHelper
  it "should use the repo name given by github, not the user" do
    running :create, "My Super Repo" do
      setup_github_token
      @command.should_receive(:sh).
        with("curl -F 'repository[name]=My Super Repo' -F 'repository[public]=true' -F 'login=drnic' -F 'token=MY_GITHUB_TOKEN' https://github.com/repositories").
        once.
        and_return("<html><body>You are being <a href=\"https://github.com/drnic/My-Super-Repo\">redirected</a>.</body></html>")
        
      @command.should_receive(:mkdir).with("My Super Repo").once
      @command.should_receive(:cd).with("My Super Repo").once
      @command.should_receive(:git).with("init").once
      @command.should_receive(:touch).with("README").once
      @command.should_receive(:git).with("add *").once
      @command.should_receive(:git).with("commit -m 'First commit!'").once
      @command.should_receive(:git).with("remote add origin git@github.com:drnic/My-Super-Repo.git").once
      @command.should_receive(:git_exec).with("push origin master").once
    end
  end
end