require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github clone" do
  include CommandHelper
  
  # -- clone --
  specify "clone should die with no args" do
    running :clone do
      @command.should_receive(:die).with("Specify a user to pull from").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end

  specify "clone should fall through with just one arg" do
    running :clone, "git://git.kernel.org/linux.git" do
      @command.should_receive(:git_exec).with("clone git://git.kernel.org/linux.git")
    end
  end

  specify "clone defunkt github-gem should clone the repo" do
    running :clone, "defunkt", "github-gem" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git")
    end
  end

  specify "clone defunkt/github-gem should clone the repo" do
    running :clone, "defunkt/github-gem" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git")
    end
  end

  specify "clone --ssh defunkt github-gem should clone the repo using the private URL" do
    running :clone, "--ssh", "defunkt", "github-gem" do
      @command.should_receive(:git_exec).with("clone git@github.com:defunkt/github-gem.git")
    end
  end

  specify "clone defunkt github-gem repo should clone the repo into the dir 'repo'" do
    running :clone, "defunkt", "github-gem", "repo" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git repo")
    end
  end

  specify "clone defunkt/github-gem repo should clone the repo into the dir 'repo'" do
    running :clone, "defunkt/github-gem", "repo" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git repo")
    end
  end

  specify "clone --ssh defunkt github-gem repo should clone the repo using the private URL into the dir 'repo'" do
    running :clone, "--ssh", "defunkt", "github-gem", "repo" do
      @command.should_receive(:git_exec).with("clone git@github.com:defunkt/github-gem.git repo")
    end
  end

  specify "clone defunkt/github-gem repo should clone the repo into the dir 'repo'" do
    running :clone, "defunkt/github-gem", "repo" do
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git repo")
    end
  end
  
  specify "clone a selected repo after showing search results" do
    running :clone, "--search", "github-gem" do
      json = StringIO.new '{"repositories":[' +
      '{"name":"github-gem","size":300,"followers":499,"username":"defunkt","language":"Ruby","fork":false,"id":"repo-1653","type":"repo","pushed":"2008-12-04T03:14:00Z","forks":59,"description":"The official `github` command line helper for simplifying your GitHub experience.","score":3.4152448,"created":"2008-02-28T09:35:34Z"},' +
      '{"name":"github-gem-builder","size":76,"followers":26,"username":"pjhyett","language":"Ruby","fork":false,"id":"repo-67489","type":"repo","pushed":"2008-11-04T04:54:57Z","forks":3,"description":"The scripts used to build RubyGems on GitHub","score":3.4152448,"created":"2008-10-24T22:29:32Z"}' +
      ']}'
      json.rewind
      question_list = <<-LIST.gsub(/^      /, '').split("\n").compact
      defunkt/github-gem         # The official `github` command line helper for simplifying your GitHub experience.
      pjhyett/github-gem-builder # The scripts used to build RubyGems on GitHub
      LIST
      @command.should_receive(:open).with("https://github.com/api/v1/json/search/github-gem").and_return(json)
      GitHub::UI.should_receive(:display_select_list).with(question_list).
        and_return("defunkt/github-gem")
      @command.should_receive(:current_user?).and_return(nil)
      @command.should_receive(:git_exec).with("clone git://github.com/defunkt/github-gem.git")
    end
  end
  
end
