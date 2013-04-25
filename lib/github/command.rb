require 'fileutils'

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
    include FileUtils

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

    def git(command)
      run :sh, command
    end

    def git_exec(command)
      run :exec, command
    end

    def run(method, command)
      if command.is_a? Array
        command = [ 'git', command ].flatten
        GitHub.learn command.join(' ')
      else
        command = 'git ' + command
        GitHub.learn command
      end

      send method, *command
    end

    def sh(*command)
      Shell.new(*command).run
    end

    def die(message)
      puts "=> #{message}"
      exit!
    end

    def github_user
      user = git("config --get github.user")
      if user.empty?
        request_github_credentials
        user = github_user
      end
      user
    end

    def github_token
      token = git("config --get github.oauth")
      if token.empty?
        request_github_credentials
        token = github_token
      end
      token
    end
    
    def request_github_credentials
      puts "Please enter your GitHub credentials:"
      user = highline.ask("Username: ") while user.nil? || user.empty?
      
      git("config --global github.user '#{user}'")
      puts "We now need to ask you to give your GitHub password."
      puts("We use this to generate OAuth token and store that. Password will not be persisted.")

      token = highline.ask("Password: ") { |q| q.echo = false }
      data = JSON.parse(`curl -s -L -u '#{github_user}:#{token}' --data-binary '{"scopes":["repo","gist"],"note":"GitHub Gem"}' -X POST https://api.github.com/authorizations`)
      git("config --global github.oauth '#{data["token"]}'")
      true
    end

    # is the current user in the given org?
    def in_org?(name)
      command = "curl -H 'Authorization: token #{github_token}' https://api.github.com/user/orgs"
      output_json = sh command
      orgs = JSON.parse(output_json)
      return orgs.find {|o| o['login']==name }!=nil
    end

    def highline
      @highline ||= HighLine.new
    end

    def shell_user
      ENV['USER']
    end

    def current_user?(user)
      user == github_user || user == shell_user
    end

    class Shell < String
      attr_reader :error
      attr_reader :out

      def initialize(*command)
        @command = command
      end

      def run
        GitHub.debug "sh: #{command}"

        out = err = nil
        Open3.popen3(*@command) do |_, pout, perr|
          out = pout.read.strip
          err = perr.read.strip
        end

        replace @error = err unless err.empty?
        replace @out = out unless out.empty?

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

  class GitCommand < Command
    def initialize(name)
      @name = name
    end

    def command(*args)
      git_exec [ @name, args ]
    end
  end
end
