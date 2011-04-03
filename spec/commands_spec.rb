require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path("../commands/command_helper", __FILE__)

describe "github" do
  include CommandHelper

  # -- fallthrough to git if unknown command --
  specify "should fall through to actual git commands" do
    running :commit do
      @command.should_receive(:git_exec).with(["commit", []])
    end
  end

  specify "should pass along arguments when falling through" do
    running :commit, '-a', '-m', 'yo mama' do
      @command.should_receive(:git_exec).with(["commit", ["-a", "-m", 'yo mama']])
    end
  end

  # -- default --
  specify "should print the default message" do
    running :default do
      GitHub.should_receive(:descriptions).any_number_of_times.and_return({
        "home" => "Open the home page",
        "browsing" => "Browse the github page for this branch",
        "commands" => "description",
        "tracking" => "Track a new repo"
      })
      GitHub.should_receive(:flag_descriptions).any_number_of_times.and_return({
        "home" => {:flag => "Flag description"},
        "browsing" => {},
        "commands" => {},
        "tracking" => {:flag1 => "Flag one", :flag2 => "Flag two"}
      })
      @command.should_receive(:puts).with(<<-EOS.gsub(/^      /, ''))
      Usage: github command <space separated arguments>
      Available commands:
        browsing => Browse the github page for this branch
        commands => description
        home     => Open the home page
                    --flag: Flag description
        tracking => Track a new repo
                    --flag1: Flag one
                    --flag2: Flag two
      EOS
    end
  end

end
