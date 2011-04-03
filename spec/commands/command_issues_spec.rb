require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github issues" do
  include CommandHelper
  
  specify "issues without args should show help" do
    running :issues do
      setup_url_for
      stdout.should == <<-EOS.gsub(/^      /, '')
      You have to provide a command :
      
        open           - shows open tickets for this project
        closed         - shows closed tickets for this project
      
          --user=<username>   - show issues from <username>'s repository
          --after=<date>      - only show issues updated after <date>
      
      EOS
    end
  end
    
  specify "issues web opens the project's issues page" do
    running :issues, "open" do
      setup_url_for
      mock_issues_for "open"
      stdout.should == <<-EOS.gsub(/^      /, '')
      -----
      Issue #1 (0 votes): members.json 500 error
      *  Opened about 10 hours ago by bug_finder
      *  Last updated 5 minutes ago
      
      I have a nasty bug.
      -----
      EOS
    end
  end

  specify "issues web closed the project's issues page" do
    running :issues, "closed" do
      setup_url_for
      mock_issues_for "closed"
      stdout.should == <<-EOS.gsub(/^      /, '')
      -----
      Issue #1 (0 votes): members.json 500 error
      *  Opened about 10 hours ago by bug_finder
      *  Closed 5 minutes ago
      *  Last updated 5 minutes ago
      
      I have a nasty bug.
      -----
      EOS
    end
  end

  specify "issues web opens the project's issues page" do
    running :issues, "web" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/user/project/issues")
    end
  end

  specify "issues web <user> opens the project's issues page for a user repo" do
    running :issues, "web", "drnic" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/drnic/project/issues")
    end
  end
  
  class CommandHelper::Runner
    def mock_issues_for(state = "open", options = {})
      options[:updated_at] = 5.minutes.ago
      options[:closed_at]  = 5.minutes.ago
      options[:created_at] = 10.hours.ago
      options[:user]       = "user"
      options[:project]    = "project"
      yaml = <<-YAML.gsub(/^    /, '')
      --- 
      issues: 
      - number: 1
        votes: 0
        created_at: #{options[:created_at].strftime("%Y-%m-%d %H:%M:%S %z")}
        body: |-
          I have a nasty bug.
        title: members.json 500 error
        updated_at: #{options[:updated_at].strftime("%Y-%m-%d %H:%M:%S %z")}
        #{"closed_at: #{options[:closed_at].strftime("%Y-%m-%d %H:%M:%S %z")}" if state == "closed"}
        user: bug_finder
        labels: []

        state: #{state}
      YAML
      api_url = "https://github.com/api/v2/yaml/issues/list/#{options[:user]}/#{options[:project]}/#{state}"
      @command.should_receive(:open).with(api_url).and_return(yaml)
    end
  end
end