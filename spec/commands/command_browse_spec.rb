require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github browse" do
  include CommandHelper
  
  specify "browse should open the project home page with the current branch" do
    running :browse do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @helper.should_receive(:open).once.with("https://github.com/user/project/tree/test-branch")
    end
  end

  specify "browse pending should open the project home page with the 'pending' branch" do
    running :browse, "pending" do
      setup_url_for
      setup_user_and_branch("user", "test-branch")
      @helper.should_receive(:open).once.with("https://github.com/user/project/tree/pending")
    end
  end

  specify "browse defunkt pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt", "pending" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project/tree/pending")
    end
  end

  specify "browse defunkt/pending should open the home page of defunkt's fork with the 'pending' branch" do
    running :browse, "defunkt/pending" do
      setup_url_for
      @helper.should_receive(:open).once.with("https://github.com/defunkt/project/tree/pending")
    end
  end
end