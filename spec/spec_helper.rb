require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/github'

class Module
  def metaclass
    class << self;self;end
  end
end

module Spec::Example::ExampleGroupSubclassMethods
  def add_guard(klass, name, is_class = false)
    guarded = nil # define variable now for scoping
    target = (is_class ? klass.metaclass : klass)
    sep = (is_class ? "." : "#")
    target.class_eval do
      guarded = instance_method(name)
      define_method name do |*args|
        raise "Testing guards violated: Cannot call #{klass}#{sep}#{name}"
      end
    end
    @guards ||= []
    @guards << [klass, name, is_class, guarded]
  end

  def add_class_guard(klass, name)
    add_guard(klass, name, true)
  end

  def unguard(klass, name, is_class = false)
    row = @guards.find { |(k,n,i)| k == klass and n == name and i == is_class }
    raise "#{klass}#{is_class ? "." : "#"}#{name} is not guarded" if row.nil?
    (is_class ? klass.metaclass : klass).class_eval do
      define_method name, row.last
    end
    @guards.delete row
  end

  def class_unguard(klass, name)
    unguard(klass, name, true)
  end

  def unguard_all
    @guards ||= []
    @guards.each do |klass, name, is_class, guarded|
      (is_class ? klass.metaclass : klass).class_eval do
        define_method name, guarded
      end
    end
    @guards.clear
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

  configuration.prepend_before(:all) do
    self.class.send :include, Spec::Example::ExampleGroupSubclassMethods
  end

  configuration.prepend_before(:each) do
    add_guard Kernel, :`
    add_guard Kernel, :system
    add_class_guard Process, :fork
    add_class_guard Open3, :popen3 if defined? Open3
  end

  configuration.append_after(:each) do
    unguard_all
  end
end
