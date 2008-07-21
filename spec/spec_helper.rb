require 'rubygems'
require 'spec'

require File.dirname(__FILE__) + '/../lib/github'

class Module
  def metaclass
    class << self;self;end
  end
end

class Spec::NextInstanceProxy
  def initialize
    @deferred = []
  end

  def method_missing(sym, *args)
    proxy = Spec::NextInstanceProxy.new
    @deferred << [sym, args, proxy]
    proxy
  end

  def should_receive(*args)
    method_missing(:should_receive, *args)
  end
  alias stub! should_receive

  def invoke(obj)
    @deferred.each do |(sym, args, proxy)|
      result = obj.send(sym, *args)
      proxy.invoke(result)
    end
  end
end

class Class
  def next_instance
    meth = metaclass.instance_method(:new)
    proxy = Spec::NextInstanceProxy.new
    metaclass.send :define_method, :new do |*args|
      instance = meth.bind(self).call(*args)
      proxy.invoke(instance)
      metaclass.send :define_method, :new, meth
      instance
    end
    proxy
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
  configuration.prepend_after(:each) do
    GitHub.instance_variable_set :'@options', nil
    GitHub.instance_variable_set :'@debug', nil
  end

  configuration.prepend_before(:all) do
    self.class.send :include, Spec::Example::ExampleGroupSubclassMethods
  end

  configuration.prepend_before(:each) do
    add_guard Kernel, :`
    add_guard Kernel, :system
    add_guard Kernel, :fork
    add_guard Kernel, :exec
    add_class_guard Process, :fork
  end

  configuration.append_after(:each) do
    unguard_all
  end
end

# include this in any example group that defines @helper
module SetupMethods
  def setup_user_and_branch(user = :user, branch = :master)
    @helper.should_receive(:user_and_branch).any_number_of_times.and_return([user, branch])
  end

  def setup_url_for(remote = :origin, user = nil, project = :project)
    if user.nil?
      user = remote
      user = "user" if remote == :origin
    end
    @helper.should_receive(:url_for).any_number_of_times.with(remote).and_return("git://github.com/#{user}/#{project}.git")
  end
end

class HelperRunner
  def initialize(parent, name)
    @parent = parent
    @name = name
  end

  def run(&block)
    self.instance_eval(&block)
  end

  def it(str, &block)
    @parent.send :it, "#{@name} #{str}", &block
  end
  alias specify it
end

module CommandRunner
  def running(cmd, *args, &block)
    Runner.new(self, cmd, *args, &block).run
  end

  class Runner
    include SetupMethods

    def initialize(parent, cmd, *args, &block)
      @cmd_name = cmd.to_s
      @command = GitHub.commands[cmd.to_s]
      @helper = @command.helper
      @args = args
      @block = block
      @parent = parent
    end

    def run
      self.instance_eval &@block
      mock_remotes unless @remotes.nil?
      GitHub.should_receive(:load).with("commands.rb")
      GitHub.should_receive(:load).with("helpers.rb")
      args = @args.clone
      GitHub.parse_options(args) # strip out the flags
      GitHub.should_receive(:invoke).with(@cmd_name, *args).and_return do
        GitHub.send(GitHub.send(:__mock_proxy).send(:munge, :invoke), @cmd_name, *args)
      end
      invoke = lambda { GitHub.activate([@cmd_name, *@args]) }
      if @expected_result
        expectation, result = @expected_result
        case result
        when Spec::Matchers::RaiseError, Spec::Matchers::Change, Spec::Matchers::ThrowSymbol
          invoke.send expectation, result
        else
          invoke.call.send expectation, result
        end
      else
        invoke.call
      end
      @stdout_mock.invoke unless @stdout_mock.nil?
      @stderr_mock.invoke unless @stderr_mock.nil?
    end

    def setup_remote(remote, options = {:user => nil, :project => "project"})
      @remotes ||= {}
      user = options[:user] || remote
      project = options[:project]
      ssh = options[:ssh]
      url = options[:url]
      if url
        @remotes[remote.to_sym] = url
      elsif ssh
        @remotes[remote.to_sym] = "git@github.com:#{user}/#{project}.git"
      else
        @remotes[remote.to_sym] = "git://github.com/#{user}/#{project}.git"
      end
    end

    def mock_remotes()
      @helper.should_receive(:remotes).any_number_of_times.and_return(@remotes)
    end

    def should(result)
      @expected_result = [:should, result]
    end

    def should_not(result)
      @expected_result = [:should_not, result]
    end

    def stdout
      if @stdout_mock.nil?
        output = ""
        @stdout_mock = DeferredMock.new(output)
        STDOUT.should_receive(:write).any_number_of_times do |str|
          output << str
        end
      end
      @stdout_mock
    end

    def stderr
      if @stderr_mock.nil?
        output = ""
        @stderr_mock = DeferredMock.new(output)
        STDERR.should_receive(:write).any_number_of_times do |str|
          output << str
        end
      end
      @stderr_mock
    end

    class DeferredMock
      def initialize(obj = nil)
        @obj = obj
        @calls = []
        @expectations = []
      end

      attr_reader :obj

      def invoke(obj = nil)
        obj ||= @obj
        @calls.each do |sym, args|
          obj.send sym, *args
        end
        @expectations.each do |exp|
          exp.invoke
        end
      end

      def should(*args)
        if args.empty?
          exp = Expectation.new(self, :should)
          @expectations << exp
          exp
        else
          @calls << [:should, args]
        end
      end

      def should_not(*args)
        if args.empty?
          exp = Expectation.new(self, :should_not)
          @expectations << exp
          exp
        else
          @calls << [:should_not, args]
        end
      end

      class Expectation
        def initialize(mock, call)
          @mock = mock
          @call = call
          @calls = []
        end

        undef_method *(instance_methods.map { |x| x.to_sym } - [:__id__, :__send__])

        def invoke
          @calls.each do |sym, args|
            (@mock.obj.send @call).send sym, *args
          end
        end

        def method_missing(sym, *args)
          @calls << [sym, args]
        end
      end
    end

    def method_missing(sym, *args)
      @parent.send sym, *args
    end
  end
end
