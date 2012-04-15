$:.unshift File.dirname(__FILE__)
require 'github/extensions'
require 'github/command'
require 'github/helper'
require 'github/ui'
require 'fileutils'
require 'rubygems'
require 'open-uri'
require 'json'
require 'yaml'
require 'text/format'

##
# Starting simple.
#
# $ github <command> <args>
#
#   GitHub.command <command> do |*args|
#     whatever
#   end
#

module GitHub
  extend self

  BasePath = File.expand_path(File.dirname(__FILE__))

  def command(command, options = {}, &block)
    command = command.to_s
    debug "Registered `#{command}`"
    descriptions[command] = @next_description if @next_description
    @next_description = nil
    flag_descriptions[command].update @next_flags if @next_flags
    usage_descriptions[command] = @next_usage if @next_usage
    @next_flags = nil
    @next_usage = []
    commands[command] = Command.new(block)
    Array(options[:alias] || options[:aliases]).each do |command_alias|
      commands[command_alias.to_s] = commands[command.to_s]
    end
  end

  def desc(str)
    @next_description = str
  end

  def flags(hash)
    @next_flags ||= {}
    @next_flags.update hash
  end

  def usage(string)
    @next_usage ||= []
    @next_usage << string
  end

  def helper(command, &block)
    debug "Helper'd `#{command}`"
    Helper.send :define_method, command, &block
  end

  def activate(args)
    @@original_args = args.clone
    @options = parse_options(args)
    @debug = @options.delete(:debug)
    @learn = @options.delete(:learn)
    Dir[BasePath + '/commands/*.rb'].each do |command|
      load command
    end
    # load user local extensions
    Dir[ENV['HOME']+ '/.github-gem/commands/*.rb'].each do |command|
      load command
    end
    invoke(args.shift, *args)
  end

  def invoke(command, *args)
    block = find_command(command)
    debug "Invoking `#{command}`"
    block.call(*args)
  end

  def find_command(name)
    name = name.to_s
    commands[name] || (commands[name] = GitCommand.new(name)) || commands['default']
  end

  def commands
    @commands ||= {}
  end

  def descriptions
    @descriptions ||= {}
  end

  def flag_descriptions
    @flagdescs ||= Hash.new { |h, k| h[k] = {} }
  end

  def usage_descriptions
    @usage_descriptions ||= Hash.new { |h, k| h[k] = [] }
  end

  def options
    @options
  end

  def original_args
    @@original_args ||= []
  end

  def parse_options(args)
    idx = 0
    args.clone.inject({}) do |memo, arg|
      case arg
      when /^--(.+?)=(.*)/
        args.delete_at(idx)
        memo.merge($1.to_sym => $2)
      when /^--(.+)/
        args.delete_at(idx)
        memo.merge($1.to_sym => true)
      when "--"
        args.delete_at(idx)
        return memo
      else
        idx += 1
        memo
      end
    end
  end

  def debug(*messages)
    puts *messages.map { |m| "== #{m}" } if debug?
  end

  def learn(message)
    if learn?
      puts "== " + Color.yellow(message)
    else
      debug(message)
    end
  end

  def learn?
    !!@learn
  end

  def debug?
    !!@debug
  end

  def load(file)
    file =~ /^\// ? path = file : path = BasePath + "/commands/#{File.basename(file)}"
    data = File.read(path)
    GitHub.module_eval data, path
  end
end

GitHub.command :default, :aliases => ['', '-h', 'help', '-help', '--help'] do
  message = []
  message << "Usage: github command <space separated arguments>"
  message << "Available commands:"
  longest = GitHub.descriptions.map { |d,| d.to_s.size }.max
  indent = longest + 6 # length of "  " + " => "
  fmt = Text::Format.new(
    :first_indent => indent,
    :body_indent => indent,
    :columns => 79 # be a little more lenient than the default
  )
  sorted = GitHub.descriptions.keys.sort
  sorted.each do |command|
    desc = GitHub.descriptions[command]
    cmdstr = "%-#{longest}s" % command
    desc = fmt.format(desc).strip # strip to eat first "indent"
    message << "  #{cmdstr} => #{desc}"
    flongest = GitHub.flag_descriptions[command].map { |d,| "--#{d}".size }.max
    ffmt = fmt.clone
    ffmt.body_indent += 2 # length of "% " and/or "--"
    GitHub.usage_descriptions[command].each do |usage_descriptions|
      usage_descriptions.split("\n").each do |usage|
        usage_str = "%% %-#{flongest}s" % usage
        message << ffmt.format(usage_str)
      end
    end
    GitHub.flag_descriptions[command].sort {|a,b| a.to_s <=> b.to_s }.each do |flag, fdesc|
      flagstr = "#{" " * longest}  %-#{flongest}s" % "--#{flag}"
      message << ffmt.format("  #{flagstr}: #{fdesc}")
    end
  end
  puts message.map { |m| m.gsub(/\n$/,'') }.join("\n") + "\n"
end
