require File.dirname(__FILE__) + '/spec_helper'

describe "github" do
  it "home should open the project home page" do
    running :home do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/user/project/tree/master")
    end
  end

  it "home defunkt should open the home page of defunkt's fork" do
    running :home, "defunkt" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/tree/master")
    end
  end

  it "browse should open the project home page with the current branch" do
    running :browse do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @command.should_receive(:exec).once.with("open https://github.com/user/project/tree/test-branch")
    end
  end

  it "browse pending should open the project home page with the 'pending' branch" do
    running :browse, "pending" do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @command.should_receive(:exec).once.with("open https://github.com/user/project/tree/pending")
    end
  end

  it "browse defunkt pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt", "pending" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/tree/pending")
    end
  end

  it "browse defunkt/pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt/pending" do
      setup_url_for
      @command.should_receive(:exec).once.with("open https://github.com/defunkt/project/tree/pending")
    end
  end

  it "info should show info for this project" do
    running :info do
      setup_url_for
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:defunkt)
      output = ""
      @command.should_receive(:puts).any_number_of_times do |str|
        output << str
        output << "\n" unless output[-1] == "\n"
      end
      post_run do
        output.should == <<-EOF
== Info for project
You are user
Currently tracking:
 - user (as origin)
 - defunkt (as defunkt)
EOF
      end
    end
  end

  # -----------------

  def running(cmd, *args, &block)
    Runner.new(cmd, *args, &block).run
  end

  class Runner
    def initialize(cmd, *args, &block)
      @cmd_name = cmd.to_s
      @command = GitHub.commands[cmd.to_s]
      @helper = @command.helper
      @args = args
      @block = block
      @remotes = []
      mock_remotes
    end

    def run
      self.instance_eval &@block
      GitHub.invoke(@cmd_name, *@args)
      @post_run.call unless @post_run.nil?
    end

    def post_run(&block)
      @post_run = block
    end

    def setup_user_and_branch(user = :user, branch = :master)
      @helper.should_receive(:user_and_branch).any_number_of_times.and_return([user, branch])
    end

    def setup_url_for(remote = :origin, user = nil, project = :project)
      if user.nil?
        user = remote
        user = "user" if remote == :origin
      end
      @helper.should_receive(:url_for).any_number_of_times.with(remote).and_return("git://github.com/#{user}/#{project}")
    end

    def setup_remote(remote, options = {:user => nil, :project => "project"})
      user = options[:user] || remote
      project = options[:project]
      ssh = options[:ssh]
      if ssh
        @remotes << [remote, "git@github.com:#{user}/#{project}.git"]
      else
        @remotes << [remote, "git://github.com/#{user}/#{project}.git"]
      end
      mock_remotes
    end

    def mock_remotes()
      @helper.should_receive(:remotes).any_number_of_times.and_return(@remotes)
    end
  end
end
