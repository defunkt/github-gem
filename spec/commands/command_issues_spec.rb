require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.dirname(__FILE__) + '/command_helper'

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
end