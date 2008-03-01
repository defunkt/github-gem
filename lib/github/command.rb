require 'open3'

module GitHub
  class Command
    def initialize(block)
      @block = block
    end

    def call(*args)
      arity = @block.arity
      args << nil while args.size < arity
      @block.call(*args)
    end
    
    def helper
      @helper ||= Helper.new
    end

    def git(*command)
      sh ['git', command].flatten.join(' ')
    end

    def sh(*command)
      Shell.new(*command).run
    end

    def die(message)
      puts "=> #{message}"
      exit!
    end

    class Shell < String
      def initialize(*command)
        @command = command
      end

      def run
        GitHub.debug "sh: #{command}"
        _, out, err = Open3.popen3(*@command)

        out = out.read.strip
        err = err.read.strip

        if out.any?
          replace @out = out
        elsif err.any?
          replace @error = err
        end
      end

      def command
        @command.join(' ')
      end

      def error?
        !!@error
      end

      def out?
        !!@out
      end
    end
  end
end
