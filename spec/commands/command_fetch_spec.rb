require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github fetch" do
  include CommandHelper
  
  specify "fetch should die with no args" do
    running :fetch do
      @command.should_receive(:die).with("Specify a user to pull from").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "fetch defunkt should start tracking defunkt if they're not already tracked" do
    running :fetch, "defunkt" do
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:external, :url => "home:/path/to/project.git")
      GitHub.should_receive(:invoke).with(:track, "defunkt").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "fetch defunkt should create defunkt/master and fetch from the defunkt remote" do
    running :fetch, "defunkt" do
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt master:refs/remotes/defunkt/master").ordered
      @command.should_receive(:git).with("update-ref refs/heads/defunkt/master refs/remotes/defunkt/master").ordered
      @command.should_receive(:git_exec).with("checkout defunkt/master").ordered
      stdout.should == "Fetching defunkt/master\n"
    end
  end

  specify "fetch defunkt/wip should create defunkt/wip and fetch from wip branch on defunkt remote" do
    running :fetch, "defunkt/wip" do
      setup_remote(:defunkt, :remote_branches => ["master", "wip"])
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt wip:refs/remotes/defunkt/wip").ordered
      @command.should_receive(:git).with("update-ref refs/heads/defunkt/wip refs/remotes/defunkt/wip").ordered
      @command.should_receive(:git_exec).with("checkout defunkt/wip").ordered
      stdout.should == "Fetching defunkt/wip\n"
    end
  end

  specify "fetch --merge defunkt should fetch from defunkt remote into current branch" do
    running :fetch, "--merge", "defunkt" do
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt master:refs/remotes/defunkt/master").ordered
      @command.should_receive(:git).with("update-ref refs/heads/defunkt/master refs/remotes/defunkt/master").ordered
      @command.should_receive(:git_exec).with("checkout defunkt/master").ordered
      stdout.should == "Fetching defunkt/master\n"
    end
  end

end