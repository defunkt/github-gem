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
    end

    def run
      self.instance_eval &@block
      GitHub.invoke(@cmd_name, *@args)
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
  end
end
