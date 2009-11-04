require "readline"
require "highline"
module GitHub
  module UI
    extend self
    def display_select_list(list)
      HighLine.track_eof = false
      HighLine.new.choose do |menu|
        list.each { |item| menu.choice item }
        menu.header = "Select a repository to clone"
      end
    end
  end
end