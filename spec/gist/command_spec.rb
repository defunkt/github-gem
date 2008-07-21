require File.dirname(__FILE__) + '/spec_helper'

describe "github" do
  include CommandRunner

  # -- home --
  specify "home should open the gist homepage" do
    running :home do
      @helper.should_receive(:open).with("http://gist.github.com")
    end
  end

  specify "home defunkt should open defunkt's gist homepage" do
    running :home, "defunkt" do
      @helper.should_receive(:open).with("http://gist.github.com/defunkt")
    end
  end
end
