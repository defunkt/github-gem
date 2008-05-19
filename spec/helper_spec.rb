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
      @helper.user_and_repo_from("home:path/to/repo.git").should == ['', '']
    end

    it "should return nothing for invalid git:// urls" do
      @helper.user_and_repo_from("git://github.com/foo").should == ['', '']
    end

    it "should return nothing for invalid ssh-based urls" do
      @helper.user_and_repo_from("git@github.com:kballard").should == ['', '']
      @helper.user_and_repo_from("git@github.com:kballard/test/repo.git").should == ['', '']
      @helper.user_and_repo_from("ssh://git@github.com:kballard").should == ['', '']
      @helper.user_and_repo_from("github.com:kballard").should == ['', '']
      @helper.user_and_repo_from("ssh://github.com:kballard").should == ['', '']
    end
  end

  helper :user_for do
    it "should return defunkt" do
      setup_url_for :origin, "defunkt"
      @helper.user_for(:origin).should == "defunkt"
    end
  end
end
