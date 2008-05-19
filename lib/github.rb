$:.unshift File.dirname(__FILE__)
require 'extensions'
require 'github/command'
require 'github/helper'
require 'rubygems'
require 'launchy'

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

  def register(command, &block)
    debug "Registered `#{command}`"
    commands[command.to_s] = Command.new(block)
  end

  def describe(hash)
    descriptions.update hash
  end

  def flags(command, hash)
    flag_descriptions[command].update hash
  end

  def helper(command, &block)
    debug "Helper'd `#{command}`"
    Helper.send :define_method, command, &block
  end

  def activate(args)
    @options = parse_options(args)
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
    file[0] == ?/ ? super : super(BasePath + "/commands/#{file}")
  end

  def debug(*messages)
    puts *messages.map { |m| "== #{m}" } if debug?
  end

  def debug?
    !!@debug
  end
end

GitHub.register :default do
  puts "Usage: github command <space separated arguments>", ''
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
