if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    require 'win32/open3'
  rescue LoadError
    warn "You must 'gem install win32-open3' to use the github command on Windows"
    exit 1
  end
else
  require 'open3'
end

module GitHub
  class Command
    def initialize(block)
      (class << self;self end).send :define_method, :command, &block
    end

    def call(*args)
      arity = method(:command).arity
      args << nil while args.size < arity
      send :command, *args
    end
    
    def helper
      @helper ||= Helper.new
    end

    def options
      GitHub.options
    end

    def pgit(*command)
      puts git(*command)
    end

    def git(*command)
      sh ['git', command].flatten.join(' ')
    end

    def git_exec(*command)
      cmdstr = ['git', command].flatten.join(' ')
      GitHub.debug "exec: #{cmdstr}"
      exec cmdstr
    end

    def sh(*command)
      Shell.new(*command).run
    end

    def get_network_data(user, options)
      if options[:cache] && has_cache?
        return get_cache
      end
      if cache_network_data(options)
        return cache_data(user)
      else
        return get_cache
      end
    end

    def cache_commits(commits)
      File.open( commits_cache_path, 'w' ) do |out|
        out.write(commits.to_yaml)
      end
    end
    
    def commits_cache
      YAML.load(File.open(commits_cache_path))
    end

    def cache_commits_data(options)
      cache_expired? || options[:nocache] || !has_commits_cache?
    end

    def cache_network_data(options)
      cache_expired? || options[:nocache] || !has_cache?
    end
    
    def network_cache_path
      dir = `git rev-parse --git-dir`.chomp
      File.join(dir, 'network-cache')
    end

    def commits_cache_path
      dir = `git rev-parse --git-dir`.chomp
      File.join(dir, 'commits-cache')
    end
    
    def cache_data(user)
      raw_data = open(helper.network_meta_for(user)).read
      File.open( network_cache_path, 'w' ) do |out|
        out.write(raw_data)
      end
      data = JSON.parse(raw_data)
    end
    
    def cache_expired?
      return true if !has_cache?
      age = Time.now - File.stat(network_cache_path).mtime
      return true if age > (60 * 60) # 1 hour
      false
    end
    
    def has_cache?
      File.file?(network_cache_path)
    end

    def has_commits_cache?
      File.file?(commits_cache_path)
    end
    
    def get_cache
      JSON.parse(File.read(network_cache_path))
    end
    
    def die(message)
      puts "=> #{message}"
      exit!
    end

    class Shell < String
      attr_reader :error
      attr_reader :out

      def initialize(*command)
        @command = command
      end

      def run
        GitHub.debug "sh: #{command}"
        _, out, err = Open3.popen3(*@command)
        
        out = out.read.strip
        err = err.read.strip

        replace @error = err if err.any?
        replace @out = out if out.any?

        self
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
