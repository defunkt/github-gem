require File.dirname(__FILE__) + '/spec_helper'

describe GitHub do
  it "should parse --bare options" do
    GitHub.parse_options(["--bare", "--test"]).should == {:bare => true, :test => true}
  end
end
