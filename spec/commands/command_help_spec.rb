require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "github help" do

  it "should output help contents" do
    example_output = File.expand_path(File.dirname(__FILE__) + "/../resources/help_output.txt")
    $stdout.should_receive(:write).with(File.read(example_output))
    GitHub.invoke(:default)
  end

end
