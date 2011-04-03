require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path("../command_helper", __FILE__)

describe "github info" do
  include CommandHelper
  
  specify "info should show info for this project" do
    running :info do
      setup_url_for
      setup_remote(:origin, :user => "user", :ssh => true)
      setup_remote(:defunkt)
      setup_remote(:external, :url => "home:/path/to/project.git")
      stdout.should == <<-EOF
== Info for project
You are user
Currently tracking:
 - defunkt (as defunkt)
 - home:/path/to/project.git (as external)
 - user (as origin)
EOF
    end
  end
end