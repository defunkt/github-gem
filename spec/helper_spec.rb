require File.dirname(__FILE__) + '/spec_helper'

class HelperRunner
  def initialize(parent, name)
    @parent = parent
    @name = name
  end

  def run(&block)
    self.instance_eval(&block)
  end

  def it(str, &block)
    @parent.send :it, "#{@name} #{str}", &block
  end
  alias specify it
end

describe GitHub::Helper do
  include SetupMethods

  def self.helper(name, &block)
    HelperRunner.new(self, name).run(&block)
  end

  before(:each) do
    @helper = GitHub::Helper.new
  end

  helper :owner do
    it "should return repo owner" do
      setup_url_for :origin, "hacker"
      @helper.owner.should == "hacker"
    end
  end

  helper :private_url_for do
    it "should return ssh-style url" do
      setup_url_for :origin, "user", "merb-core"
      @helper.private_url_for("wycats").should == "git@github.com:wycats/merb-core.git"
    end
  end

  helper :project do
    it "should return project-awesome" do
      setup_url_for :origin, "user", "project-awesome"
      @helper.project.should == "project-awesome"
    end

    it "should exit due to missing origin" do
      @helper.should_receive(:url_for).twice.with(:origin).and_return("")
      STDERR.should_receive(:puts).with("Error: missing remote 'origin'")
      lambda { @helper.project }.should raise_error(SystemExit)
    end

    it "should exit due to non-github origin" do
      @helper.should_receive(:url_for).twice.with(:origin).and_return("home:path/to/repo.git")
      STDERR.should_receive(:puts).with("Error: remote 'origin' is not a github URL")
      lambda { @helper.project }.should raise_error(SystemExit)
    end
  end

  helper :public_url_for do
    it "should return git:// URL" do
      setup_url_for :origin, "user", "merb-core"
      @helper.public_url_for("wycats").should == "git://github.com/wycats/merb-core.git"
    end
  end

  helper :repo_for do
    it "should return mephisto.git" do
      setup_url_for "mojombo", "mojombo", "mephisto"
      @helper.repo_for("mojombo").should == "mephisto.git"
    end
  end

  helper :user_and_repo_from do
    it "should parse a git:// url" do
      @helper.user_and_repo_from("git://github.com/defunkt/github.git").should == ["defunkt", "github.git"]
    end

    it "should parse a ssh-based url" do
      @helper.user_and_repo_from("git@github.com:mojombo/god.git").should == ["mojombo", "god.git"]
    end

    it "should parse a non-standard ssh-based url" do
      @helper.user_and_repo_from("ssh://git@github.com:mojombo/god.git").should == ["mojombo", "god.git"]
      @helper.user_and_repo_from("github.com:mojombo/god.git").should == ["mojombo", "god.git"]
      @helper.user_and_repo_from("ssh://github.com:mojombo/god.git").should == ["mojombo", "god.git"]
    end

    it "should return nothing for other urls" do
      @helper.user_and_repo_from("home:path/to/repo.git").should == nil
    end

    it "should return nothing for invalid git:// urls" do
      @helper.user_and_repo_from("git://github.com/foo").should == nil
    end

    it "should return nothing for invalid ssh-based urls" do
      @helper.user_and_repo_from("git@github.com:kballard").should == nil
      @helper.user_and_repo_from("git@github.com:kballard/test/repo.git").should == nil
      @helper.user_and_repo_from("ssh://git@github.com:kballard").should == nil
      @helper.user_and_repo_from("github.com:kballard").should == nil
      @helper.user_and_repo_from("ssh://github.com:kballard").should == nil
    end
  end

  helper :user_for do
    it "should return defunkt" do
      setup_url_for :origin, "defunkt"
      @helper.user_for(:origin).should == "defunkt"
    end
  end

  helper :url_for do
    it "should call out to the shell" do
      @helper.should_receive(:`).with("git config --get remote.origin.url").and_return "git://github.com/user/project.git\n"
      @helper.url_for(:origin).should == "git://github.com/user/project.git"
    end
  end

  helper :remotes do
    it "should return a list of remotes" do
      @helper.should_receive(:`).with('git config --get-regexp \'^remote\.(.+)\.url$\'').and_return <<-EOF
remote.origin.url git@github.com:kballard/github-gem.git
remote.defunkt.url git://github.com/defunkt/github-gem.git
remote.nex3.url git://github.com/nex3/github-gem.git
      EOF
      @helper.remotes.should == {
        :origin => "git@github.com:kballard/github-gem.git",
        :defunkt => "git://github.com/defunkt/github-gem.git",
        :nex3 => "git://github.com/nex3/github-gem.git"
      }
    end
  end

  helper :tracking do
    it "should return a list of remote/user_or_url pairs" do
      @helper.should_receive(:remotes).and_return({
        :origin => "git@github.com:kballard/github-gem.git",
        :defunkt => "git://github.com/defunkt/github-gem.git",
        :external => "server:path/to/github-gem.git"
      })
      @helper.tracking.should == {
        :origin => "kballard",
        :defunkt => "defunkt",
        :external => "server:path/to/github-gem.git"
      }
    end
  end

  helper :tracking? do
    it "should return whether the user is tracked" do
      @helper.should_receive(:tracking).any_number_of_times.and_return({
        :origin => "kballard",
        :defunkt => "defunkt",
        :external => "server:path/to/github-gem.git"
      })
      @helper.tracking?("kballard").should == true
      @helper.tracking?("defunkt").should == true
      @helper.tracking?("nex3").should == false
    end
  end
end
