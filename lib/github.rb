$:.unshift File.dirname(__FILE__)
require 'github/command'
require 'github/helper'

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

  def activate(args)
    return if args.empty?
    @debug = args.delete('--debug')
    load 'commands.rb'
    invoke(args.shift, *args)
  end

  def invoke(command, *args)
    if block = commands[command]
      debug "Invoking `#{command}`"
      block.call(*args)
    else
      debug "Couldn't invoke `#{command}`: not found"
    end
  end

  def register(command, &block)
    debug "Registered `#{command}`"
    commands[command.to_s] = Command.new(block)
  end

  def helper(command, &block)
    debug "Helper'd `#{command}`"
    Helper.send :define_method, command, &block
  end

  def commands
    @commands ||= {}
  end

  def debug(*messages)
    puts *messages.map { |m| "== #{m}" } if debug?
  end

  def debug?
    !!@debug
  end
end

GitHub.activate ARGV
