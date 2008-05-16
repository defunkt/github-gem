require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/github'

class Spec::Example::Configuration
  def add_guard(klass, name, isclass = false)
    guarded = nil
    target = (isclass ? (class << klass;self;end) : klass)
    self.prepend_before(:all) do
      target.class_eval do
        guarded = instance_method(name)
        define_method name do |*args|
          raise "Testing guards violated: Cannot call #{klass}#{isclass ? "." : "#"}#{name}"
        end
      end
    end
    self.prepend_after(:all) do
      target.class_eval do
        if guarded.nil?
          undef_method name
        else
          define_method name, guarded
        end
      end
    end
  end

  def add_class_guard(klass, name)
    add_guard(klass, name, true)
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
  configuration.add_class_guard(Process, :fork)
  configuration.add_class_guard(Open3, :popen3) if defined? Open3
end
