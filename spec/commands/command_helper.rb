module CommandHelper
  def running(cmd, *args, &block)
    Runner.new(self, cmd, *args, &block).run
  end

  class Runner
    include SetupMethods

    def initialize(parent, cmd, *args, &block)
      @cmd_name = cmd.to_s
      @command = GitHub.find_command(cmd)
      @helper = @command.helper
      @args = args
      @block = block
      @parent = parent
    end

    def run
      self.instance_eval &@block
      mock_remotes unless @remotes.nil?
      GitHub.should_receive(:load).with(GitHub::BasePath + "/commands/commands.rb")
      GitHub.should_receive(:load).with(GitHub::BasePath + "/commands/helpers.rb")
      GitHub.should_receive(:load).with(GitHub::BasePath + "/commands/network.rb")
      GitHub.should_receive(:load).with(GitHub::BasePath + "/commands/issues.rb")
      args = @args.clone
      GitHub.parse_options(args) # strip out the flags
      GitHub.should_receive(:invoke).with(@cmd_name, *args).and_return do
        GitHub.send(GitHub.send(:__mock_proxy).send(:munge, :invoke), @cmd_name, *args)
      end
      invoke = lambda { GitHub.activate([@cmd_name, *@args]) }
      if @expected_result
        expectation, result = @expected_result
        case result
        when Spec::Matchers::RaiseException, Spec::Matchers::Change, Spec::Matchers::ThrowSymbol
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

    def setup_remote(remote, options = {:user => nil, :project => "project", :remote_branches => nil})
      @remotes ||= {}
      @remote_branches ||= {}
      user = options[:user] || remote
      project = options[:project]
      ssh = options[:ssh]
      url = options[:url]
      remote_branches = options[:remote_branches] || ["master"]
      if url
        @remotes[remote] = url
      elsif ssh
        @remotes[remote] = "git@github.com:#{user}/#{project}.git"
      else
        @remotes[remote] = "git://github.com/#{user}/#{project}.git"
      end

      @remote_branches[remote] = (@remote_branches[remote] || Array.new) | remote_branches
      @helper.should_receive(:remote_branch?).any_number_of_times.and_return do |remote, branch|
        @remote_branches.fetch(remote.to_sym,[]).include?(branch)
      end
    end

    def mock_remotes()
      @helper.should_receive(:remotes).any_number_of_times.and_return(@remotes)
    end

    def mock_members(members)
      @helper.should_receive(:network_members).any_number_of_times.and_return(members)
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
        $stdout.should_receive(:write).any_number_of_times do |str|
          output << str
        end
      end
      @stdout_mock
    end

    def stderr
      if @stderr_mock.nil?
        output = ""
        @stderr_mock = DeferredMock.new(output)
        $stderr.should_receive(:write).any_number_of_times do |str|
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
