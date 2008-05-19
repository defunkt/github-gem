require File.dirname(__FILE__) + '/spec_helper'

describe "github" do
  # -- home --
  specify "home should open the project home page" do
    running :home do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/user/project/tree/master")
    end
  end

  specify "home defunkt should open the home page of defunkt's fork" do
    running :home, "defunkt" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/tree/master")
    end
  end

  # -- browse --
  specify "browse should open the project home page with the current branch" do
    running :browse do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @command.should_receive(:exec).once.with("open https://github.com/user/project/tree/test-branch")
    end
  end

  specify "browse pending should open the project home page with the 'pending' branch" do
    running :browse, "pending" do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @command.should_receive(:exec).once.with("open https://github.com/user/project/tree/pending")
    end
  end

  specify "browse defunkt pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt", "pending" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/tree/pending")
    end
  end

  specify "browse defunkt/pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt/pending" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/tree/pending")
    end
  end

  # -- network --
  specify "network should open the network page for this repo" do
    running :network do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/user/project/network")
    end
  end

  specify "network defunkt should open the network page for defunkt's fork" do
    running :network, "defunkt" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/network")
    end
  end

  # -- info --
  specify "info should show info for this project" do
    running :info do
      setup_url_for
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:defunkt)
      setup_remote(:external, :url => "home:/path/to/project.git")
      stdout.should == <<-EOF
== Info for project
You are user
Currently tracking:
 - user (as origin)
 - defunkt (as defunkt)
 - home:/path/to/project.git (as external)
EOF
    end
  end

  # -- track --
  specify "track defunkt should track a new remote for defunkt" do
    running :track, "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(false)
      @command.should_receive(:git).with("remote add defunkt git://github.com/defunkt/project.git").once
    end
  end

  specify "track --private defunkt should track a new remove for defunkt using ssh" do
    running :track, "--private", "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(false)
      @command.should_receive(:git).with("remote add defunkt git@github.com:defunkt/project.git").once
    end
  end

  specify "track defunkt should die if the defunkt remote exists" do
    running :track, "defunkt" do
      setup_url_for
      @helper.should_receive(:tracking?).with("defunkt").once.and_return(true)
      @command.should_receive(:die).with("Already tracking defunkt").and_return { raise "Died" }
      self.should raise_error("Died")
    end
  end

  specify "track should die with no args" do
    running :track do
      @command.should_receive(:die).with("Specify a user to track").and_return { raise "Died" }
      self.should raise_error("Died")
    end
  end

  # -- pull --
  specify "pull should die with no args" do
    running :pull do
      @command.should_receive(:die).with("Specify a user to pull from").and_return { raise "Died" }
      self.should raise_error("Died")
    end
  end

  specify "pull defunkt should start tracking defunkt if they're not already tracked" do
    running :pull, "defunkt" do
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:external, :url => "home:/path/to/project.git")
      GitHub.should_receive(:invoke).with(:track, "defunkt").and_return { raise "Tracked" }
      self.should raise_error("Tracked")
    end
  end

  specify "pull defunkt should create defunkt/master and pull from the defunkt remote" do
    running :pull, "defunkt" do
      setup_remote(:defunkt)
      @command.should_receive(:git).with("checkout -b defunkt/master").ordered.and_return do
        mock("checkout -b defunkt/master").tap { |m| m.stub!(:error?) }
      end
      @command.should_receive(:git_exec).with("pull defunkt master").ordered
      stdout.should == "Switching to defunkt/master"
    end
  end

  specify "pull defunkt should switch to pre-existing defunkt/master and pull from the defunkt remote" do
    running :pull, "defunkt" do
      setup_remote(:defunkt)
      @command.should_receive(:git).with("checkout -b defunkt/master").ordered.and_return do
        mock("checkout -b defunkt/master").tap { |m| m.should_receive(:error?) { true } }
      end
      @command.should_receive(:git).with("checkout defunkt/master").ordered
      @command.should_receive(:git_exec).with("pull defunkt master").ordered
      stdout.should == "Switching to defunkt/master"
    end
  end

  specify "pull defunkt wip should create defunkt/wip and pull from wip branch on defunkt remote" do
    running :pull, "defunkt", "wip" do
      setup_remote(:defunkt)
      @command.should_receive(:git).with("checkout -b defunkt/wip").ordered.and_return do
        mock("checkout -b defunkt/wip").tap { |m| m.stub!(:error?) }
      end
      @command.should_receive(:git_exec).with("pull defunkt wip").ordered
      stdout.should == "Switching to defunkt/wip"
    end
  end

  specify "pull defunkt/wip should switch to pre-existing defunkt/wip and pull from wip branch on defunkt remote" do
    running :pull, "defunkt/wip" do
      pending "Accept user/branch syntax" do
        setup_remote(:defunkt)
        @command.should_receive(:git).with("checkout -b defunkt/wip").ordered.and_return do
          mock("checkout -b defunkt/wip").tap { |m| m.should_receive(:error?) { true } }
        end
        @command.should_receive(:git).with("checkout defunkt/wip").ordered
        @command.should_receive(:git_exec).with("pull defunkt wip").ordered
        stdout.should == "Switching to defunkt/wip"
      end
    end
  end

  specify "pull --merge defunkt should pull from defunkt remote into current branch" do
    running :pull, "--merge", "defunkt" do
      setup_remote(:defunkt)
      @command.should_receive(:git_exec).with("pull defunkt master")
    end
  end

  # -- default --
  specify "should print the default message" do
    running :default do
      GitHub.should_receive(:descriptions).any_number_of_times.and_return({
        "home" => "Open the home page",
        "track" => "Track a new repo",
        "browse" => "Browse the github page for this branch",
        "command" => "description"
      })
      GitHub.should_receive(:flag_descriptions).any_number_of_times.and_return({
        "home" => {:flag => "Flag description"},
        "track" => {:flag1 => "Flag one", :flag2 => "Flag two"},
        "browse" => {},
        "command" => {}
      })
      @command.should_receive(:puts).with("Usage: github command <space separated arguments>", '').ordered
      @command.should_receive(:puts).with("Available commands:", '').ordered
      @command.should_receive(:puts).with("  home    => Open the home page")
      @command.should_receive(:puts).with("           --flag: Flag description")
      @command.should_receive(:puts).with("  track   => Track a new repo")
      @command.should_receive(:puts).with("           --flag1: Flag one")
      @command.should_receive(:puts).with("           --flag2: Flag two")
      @command.should_receive(:puts).with("  browse  => Browse the github page for this branch")
      @command.should_receive(:puts).with("  command => description")
      @command.should_receive(:puts).with()
    end
  end

  # -----------------

  def running(cmd, *args, &block)
    Runner.new(self, cmd, *args, &block).run
  end

  class Runner
    include SetupMethods

    def initialize(parent, cmd, *args, &block)
      @cmd_name = cmd.to_s
      @command = GitHub.commands[cmd.to_s]
      @helper = @command.helper
      @args = args
      @block = block
      @parent = parent
    end

    def run
      self.instance_eval &@block
      mock_remotes unless @remotes.nil?
      GitHub.should_receive(:load).with("commands.rb")
      GitHub.should_receive(:load).with("helpers.rb")
      args = @args.clone
      GitHub.parse_options(args) # strip out the flags
      GitHub.should_receive(:invoke).with(@cmd_name, *args).and_return do
        GitHub.send(GitHub.send(:__mock_proxy).send(:munge, :invoke), @cmd_name, *args)
      end
      invoke = lambda { GitHub.activate([@cmd_name, *@args]) }
      if @expected_result
        expectation, result = @expected_result
        case result
        when Spec::Matchers::RaiseError, Spec::Matchers::Change, Spec::Matchers::ThrowSymbol
          invoke.send expectation, result
        else
          invoke.call.send expectation, result
        end
      else
        invoke.call
      end
      @stdout_mock.invoke unless @stdout_mock.nil?
    end

    def setup_remote(remote, options = {:user => nil, :project => "project"})
      @remotes ||= {}
      user = options[:user] || remote
      project = options[:project]
      ssh = options[:ssh]
      url = options[:url]
      if url
        @remotes[remote.to_sym] = url
      elsif ssh
        @remotes[remote.to_sym] = "git@github.com:#{user}/#{project}.git"
      else
        @remotes[remote.to_sym] = "git://github.com/#{user}/#{project}.git"
      end
    end

    def mock_remotes()
      @helper.should_receive(:remotes).any_number_of_times.and_return(@remotes)
    end

    def should(result)
      @expected_result = [:should, result]
    end

    def should_not(result)
      @expected_result = [:should_not, result]
    end

    def stdout
      if @stdout_mock.nil?
        output = ""
        @stdout_mock = DeferredMock.new(output)
        STDOUT.should_receive(:write).any_number_of_times do |str|
          output << str
        end
      end
      @stdout_mock
    end

    class DeferredMock
      def initialize(obj = nil)
        @obj = obj
        @calls = []
      end

      def invoke(obj = nil)
        obj ||= @obj
        @calls.each do |sym, args|
          obj.send sym, *args
        end
      end

      def should(*args)
        @calls << [:should, args]
      end

      def should_not(*args)
        @calls << [:should_not, args]
      end
    end

    def method_missing(sym, *args)
      @parent.send sym, *args
    end
  end
end
