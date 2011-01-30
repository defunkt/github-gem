require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe GitHub::Command do
  before(:each) do
    @command = GitHub::Command.new(proc { |x| puts x })
  end

  it "should return a GitHub::Helper" do
    @command.helper.should be_instance_of(GitHub::Helper)
  end

  it "should call successfully" do
    @command.should_receive(:puts).with("test").once
    @command.call("test")
  end

  it "should return options" do
    GitHub.should_receive(:options).with().once.and_return({:ssh => true})
    @command.options.should == {:ssh => true}
  end

  it "should successfully call out to the shell" do
    unguard(Kernel, :fork)
    unguard(Kernel, :exec)
    hi = @command.sh("echo hi")
    hi.should == "hi"
    hi.out.should == "hi"
    hi.out?.should be(true)
    hi.error.should be_nil
    hi.error?.should be(false)
    hi.command.should == "echo hi"
    if RUBY_PLATFORM =~ /mingw|mswin/
      command = "cmd /c echo bye >&2"
    else
      command = "echo bye >&2" 
    end
    bye = @command.sh(command)
    bye.should == "bye"
    bye.out.should be_nil
    bye.out?.should be(false)
    bye.error.should == "bye"
    bye.error?.should be(true)
    bye.command.should == command
    hi_and_bye = @command.sh("echo hi; echo bye >&2")
    hi_and_bye.should == "hi"
    hi_and_bye.out.should == "hi"
    hi_and_bye.out?.should be(true)
    hi_and_bye.error.should == "bye"
    hi_and_bye.error?.should be(true)
    hi_and_bye.command.should == "echo hi; echo bye >&2"
  end

  it "should return the results of a git operation" do
    GitHub::Command::Shell.should_receive(:new).with("git rev-parse master").once.and_return do |*cmds|
      s = mock("GitHub::Commands::Shell")
      s.should_receive(:run).once.and_return("sha1")
      s
    end
    @command.git("rev-parse master").should == "sha1"
  end

  it "should print the results of a git operation" do
    @command.should_receive(:puts).with("sha1").once
    GitHub::Command::Shell.should_receive(:new).with("git rev-parse master").once.and_return do |*cmds|
      s = mock("GitHub::Commands::Shell")
      s.should_receive(:run).once.and_return("sha1")
      s
    end
    @command.pgit("rev-parse master")
  end

  it "should exec a git command" do
    @command.should_receive(:exec).with("git rev-parse master").once
    @command.git_exec "rev-parse master"
  end

  it "should die" do
    @command.should_receive(:puts).once.with("=> message")
    @command.should_receive(:exit!).once
    @command.die "message"
  end
  
  it "requests github API credentials if not found" do
    @command.should_receive(:git).once.with("config --get github.user").and_return("")
    @command.should_receive(:puts).once.with("Please enter your GitHub credentials:")
    h = mock("HighLine")
    h.should_receive(:ask).once.with("Username: ").and_return("drnic")
    @command.should_receive(:puts).once.with("Your account token is at https://github.com/account under 'Account Admin'.")
    @command.should_receive(:puts).once.with("Press Enter to launch page in browser.")
    h.should_receive(:ask).once.with("Token: ").and_return("TOKEN")
    @command.should_receive(:highline).twice.and_return(h)
    @command.should_receive(:git).once.with("config --global github.user 'drnic'")
    @command.should_receive(:git).once.with("config --global github.token 'TOKEN'")
    @command.should_receive(:git).once.with("config --get github.user").and_return("drnic")
    @command.github_user
  end

  it "requests github API credentials if not found, and shows accounts page" do
    @command.should_receive(:git).once.with("config --get github.user").and_return("")
    @command.should_receive(:puts).once.with("Please enter your GitHub credentials:")
    h = mock("HighLine")
    h.should_receive(:ask).once.with("Username: ").and_return("drnic")
    @command.should_receive(:puts).once.with("Your account token is at https://github.com/account under 'Account Admin'.")
    @command.should_receive(:puts).once.with("Press Enter to launch page in browser.")
    h.should_receive(:ask).once.with("Token: ").and_return("")
    helper = mock("GitHub::Helper")
    helper.should_receive("open").once.with("https://github.com/account")
    @command.should_receive(:helper).once.and_return(helper)
    h.should_receive(:ask).once.with("Token: ").and_return("TOKEN")
    @command.should_receive(:highline).any_number_of_times.and_return(h)
    @command.should_receive(:git).once.with("config --global github.user 'drnic'")
    @command.should_receive(:git).once.with("config --global github.token 'TOKEN'")
    @command.should_receive(:git).once.with("config --get github.user").and_return("drnic")
    @command.github_user
  end
end
