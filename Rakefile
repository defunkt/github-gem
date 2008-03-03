require 'rubygems'
require 'rake'

begin
  require 'echoe'

  Echoe.new('github', '0.1.0') do |p|
    p.rubyforge_name = 'github'
    p.summary      = "The official `github` command line helper for simplifying your GitHub experience."
    p.description  = "The official `github` command line helper for simplifying your GitHub experience."
    p.url          = "http://github.com/"
    p.author       = 'Chris Wanstrath'
    p.email        = "chris@ozmm.org"
  end

rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end
