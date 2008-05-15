require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/github'

class Spec::Example::Configuration
  def add_guard(klass, name)
    guarded = nil
    self.prepend_before(:all) do
      klass.instance_eval do
        guarded = instance_method(name)
        define_method name do |*args|
          raise "Testing guards violated: Cannot call #{klass}##{name}"
        end
      end
    end
    self.prepend_after(:all) do
      klass.instance_eval do
        define_method name, guarded
      end
    end
  end
end

# prevent the use of `` in tests
Spec::Runner.configure do |configuration|
  # load this here so it's covered by the `` guard
  configuration.prepend_before(:all) do
    module GitHub
      load 'helpers.rb'
      load 'commands.rb'
    end
  end

  configuration.add_guard(Kernel, :`)
  configuration.add_guard(Kernel, :system)
end
