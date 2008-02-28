GitHub.register :open do 
  if remote = `git config -l`.split("\n").detect { |line| line =~ /remote.origin.url/ }
    exec "open http://github.com/#{remote.split(':').last.chomp('.git')}"
  end
end

GitHub.register :info do |repo,|
  puts "== Grabbing info for #{repo}"
end
