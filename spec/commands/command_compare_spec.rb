require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.dirname(__FILE__) + '/command_helper'

describe "github compare" do
  include CommandHelper

  context "when given two treeish objects" do
    specify "it opens the compare view between the two objects" do
      running :compare, 'gist', 'fallthrough' do
        setup_url_for "origin", "defunkt", "github-gem"

        compare_url = 'awesome'
        @helper.should_receive(:compare_for).with('defunkt', 'gist', 'fallthrough').and_return(compare_url)

        @helper.should_not_receive(:open)
        stdout.should == 'awesome'
      end
    end
  end

  context "when given one treeish object" do
    specify "it opens the compare view between master and the object" do
      running :compare, 'fallthrough' do
        setup_url_for "origin", "defunkt", "github-gem"

        compare_url = 'awesome'
        @helper.should_receive(:compare_for).with('defunkt', 'master', 'fallthrough').and_return(compare_url)

        @helper.should_not_receive(:open)
        stdout.should == 'awesome'
      end
    end
  end

  specify "it can open the URL in a browser" do
    running :compare, 'fallthrough', '--open' do
      setup_url_for "origin", "defunkt", "github-gem"

      compare_url = 'awesome'
      @helper.should_receive(:compare_for).with('defunkt', 'master', 'fallthrough').and_return(compare_url)

      stdout.should_not == 'awesome'
      @helper.should_receive('open').with(compare_url)
    end
  end
end
