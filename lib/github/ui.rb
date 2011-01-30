require 'rubygems'
require "readline"
require "highline"
module GitHub
  module UI
    extend self
    # Take a list of items, including optional ' # some description' on each and
    # return the selected item (without the description)
    def display_select_list(list)
      HighLine.track_eof = false
      long_result = HighLine.new.choose do |menu|
        list.each_with_index do |item, i|
           menu.choice((i < 9) ? " #{item}" : item)
        end
        menu.header = "Select a repository to clone"
      end
      long_result && long_result.gsub(/\s+#.*$/,'').gsub(/^\ /,'')
    end
  end
end