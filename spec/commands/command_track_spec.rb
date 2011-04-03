require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github track" do
  include CommandHelper
  
  specify "track defunkt should track a new remote for defunkt" do
    running :track, "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(false)
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/project.git").once
    end
  end

  specify "track --private defunkt should track a new remote for defunkt using ssh" do
    running :track, "--private", "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").and_return(false)
      @command.should_receive(:git).with("remote add defunkt git@github.com:defunkt/project.git")
    end
  end

  specify "track --ssh defunkt should be equivalent to track --private defunkt" do
    running :track, "--ssh", "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").and_return(false)
      @command.should_receive(:git).with("remote add defunkt git@github.com:defunkt/project.git")
    end
  end

  specify "track defunkt should die if the defunkt remote exists" do
    running :track, "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(true)
      @command.should_receive(:die).with("Already tracking defunkt").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "track should die with no args" do
    running :track do
      @command.should_receive(:die).with("Specify a user to track").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "track should accept user/project syntax" do
    running :track, "defunkt/github-gem.git" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").and_return false
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/github-gem.git")
    end
  end

  specify "track defunkt/github-gem.git should function with no origin remote" do
    running :track, "defunkt/github-gem.git" do
      @helper.stub!(:url_for).with("origin").and_return ""
      @helper.stub!(:tracking?).and_return false
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/github-gem.git")
      self.should_not raise_error(SystemExit)
      stderr.should_not =~ /^Error/
    end
  end

  specify "track origin defunkt/github-gem should track defunkt/github-gem as the origin remote" do
    running :track, "origin", "defunkt/github-gem" do
      @helper.stub!(:url_for).with("origin").and_return ""
      @helper.stub!(:tracking?).and_return false
      @command.should_receive(:git).with("remote add origin git://github.com/defunkt/github-gem.git")
      stderr.should_not =~ /^Error/
    end
  end

  specify "track --private origin defunkt/github-gem should track defunkt/github-gem as the origin remote using ssh" do
    running :track, "--private", "origin", "defunkt/github-gem" do
      @helper.stub!(:url_for).with("origin").and_return ""
      @helper.stub!(:tracking?).and_return false
      @command.should_receive(:git).with("remote add origin git@github.com:defunkt/github-gem.git")
      stderr.should_not =~ /^Error/
    end
  end
end