require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github search" do
  include CommandHelper
  
  specify "search finds multiple results" do
    running :search, "github-gem" do
      json = StringIO.new '{"repositories":[' +
      '{"name":"github-gem","size":300,"followers":499,"username":"defunkt","language":"Ruby","fork":false,"id":"repo-1653","type":"repo","pushed":"2008-12-04T03:14:00Z","forks":59,"description":"The official `github` command line helper for simplifying your GitHub experience.","score":3.4152448,"created":"2008-02-28T09:35:34Z"},' +
      '{"name":"github-gem-builder","size":76,"followers":26,"username":"pjhyett","language":"Ruby","fork":false,"id":"repo-67489","type":"repo","pushed":"2008-11-04T04:54:57Z","forks":3,"description":"The scripts used to build RubyGems on GitHub","score":3.4152448,"created":"2008-10-24T22:29:32Z"}' +
      ']}'
      json.rewind
      @command.should_receive(:open).with("https://github.com/api/v1/json/search/github-gem").and_return(json)
      stdout.should == "defunkt/github-gem\npjhyett/github-gem-builder\n"
    end
  end

  specify "search finds no results" do
    running :search, "xxxxxxxxxx" do
      json = StringIO.new '{"repositories":[]}'
      json.rewind
      @command.should_receive(:open).with("https://github.com/api/v1/json/search/xxxxxxxxxx").and_return(json)
      stdout.should == "No results found\n"
    end
  end

  specify "search shows usage if no arguments given" do
    running :search do
      @command.should_receive(:die).with("Usage: github search [query]").and_return { raise "Died" }
      self.should raise_error(RuntimeError)
    end
  end
end
