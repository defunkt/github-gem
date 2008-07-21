$:.unshift File.dirname(__FILE__)
require 'extensions'
require 'github/command'
require 'github/helper'
require 'rubygems'

##
# Starting simple.
#
# $ github <command> <args>
#
#   GitHub.register <command> do |*args|
#     whatever 
#   end
#
# We'll probably want to use the `choice` gem for concise, tasty DSL
# arg parsing action.
#

module GitHub
  extend self

  BasePath = File.expand_path(File.dirname(__FILE__) + '/..')

  @@command_name = 'github'

  def command_name=(name)
    @@command_name = name
  end
  def command_name
    @@command_name
  end

  def command(command, &block)
    debug "Registered `#{command}`"
    descriptions[command] = @next_description if @next_description
    @next_description = nil
    flag_descriptions[command].update @next_flags if @next_flags
    @next_flags = nil
    commands[command.to_s] = Command.new(block)
  end

  def desc(str)
    @next_description = str
  end

  def flags(hash)
    @next_flags ||= {}
    @next_flags.update hash
  end

  def helper(command, &block)
    debug "Helper'd `#{command}`"
    Helper.send :define_method, command, &block
  end

  def activate(args)
    @options = parse_options(args)
    @debug = @options[:debug]
    load 'helpers.rb'
    load 'commands.rb'
    invoke(args.shift, *args)
  end

  def invoke(command, *args)
    block = commands[command.to_s] || commands['default']
    debug "Invoking `#{command}`"
    block.call(*args)
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

  def options
    @options
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

  def load(file)
    if file[0] == ?/
      path = file
    else
      path = BasePath + "/commands/#{command_name}/#{file}"
      unless File.exists?(path)
        path = BasePath + "/commands/#{file}"
      end
    end
    data = File.read(path)
    GitHub.module_eval data, path
  end

  def debug(*messages)
    puts *messages.map { |m| "== #{m}" } if debug?
  end

  def debug?
    !!@debug
  end
end

GitHub.command :default do
  puts "Usage: #{GitHub.command_name} command <space separated arguments>", ''
  puts "Available commands:", ''
  longest = GitHub.descriptions.map { |d,| d.to_s.size }.max
  GitHub.descriptions.each do |command, desc|
    cmdstr = "%-#{longest}s" % command
    puts "  #{cmdstr} => #{desc}"
    flongest = GitHub.flag_descriptions[command].map { |d,| "--#{d}".size }.max
    GitHub.flag_descriptions[command].each do |flag, fdesc|
      flagstr = "#{" " * longest}  %-#{flongest}s" % "--#{flag}"
      puts "  #{flagstr}: #{fdesc}"
    end
  end
  puts
end
