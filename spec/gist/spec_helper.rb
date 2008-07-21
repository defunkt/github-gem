require File.dirname(__FILE__) + "/../spec_helper"

Spec::Runner.configure do |configuration|
  configuration.append_before(:all) do
    GitHub.command_name = 'gist'
    module GitHub
      load 'helpers.rb'
      load 'commands.rb'
    end
  end
end
