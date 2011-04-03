require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github pull" do
  include CommandHelper
  
  specify "pull defunkt should start tracking defunkt if they're not already tracked" do
    running :pull, "defunkt" do
      mock_members 'defunkt'
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:external, :url => "home:/path/to/project.git")
      GitHub.should_receive(:invoke).with(:track, "defunkt").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "pull defunkt should create defunkt/master and pull from the defunkt remote" do
    running :pull, "defunkt" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt").ordered
      @command.should_receive(:git_exec).with("checkout -b defunkt/master defunkt/master").ordered
      stdout.should == "Switching to defunkt-master\n"
    end
  end

  specify "pull defunkt should switch to pre-existing defunkt/master and pull from the defunkt remote" do
    running :pull, "defunkt" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return true
      @command.should_receive(:die).with("Unable to switch branches, your current branch has uncommitted changes").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "pull defunkt wip should create defunkt/wip and pull from wip branch on defunkt remote" do
    running :pull, "defunkt", "wip" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return true
      @command.should_receive(:die).with("Unable to switch branches, your current branch has uncommitted changes").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "pull defunkt/wip should switch to pre-existing defunkt/wip and pull from wip branch on defunkt remote" do
    running :pull, "defunkt/wip" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git).with("fetch defunkt").ordered
      @command.should_receive(:git_exec).with("checkout -b defunkt/wip defunkt/wip").ordered
      stdout.should == "Switching to defunkt-wip\n"
    end
  end

  specify "pull --merge defunkt should pull from defunkt remote into current branch" do
    running :pull, "--merge", "defunkt" do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @helper.should_receive(:branch_dirty?).and_return false
      @command.should_receive(:git_exec).with("pull defunkt master")
    end
  end

  specify "pull falls through for non-recognized commands" do
    running :pull, 'remote' do
      mock_members 'defunkt'
      setup_remote(:defunkt)
      @command.should_receive(:git_exec).with("pull remote")
    end
  end

  specify "pull passes along args when falling through" do
    running :pull, 'remote', '--stat' do
      mock_members 'defunkt'
      @command.should_receive(:git_exec).with("pull remote --stat")
    end
  end
end