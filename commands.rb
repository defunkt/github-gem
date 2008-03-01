GitHub.register :open do 
  if remote = `git config --get remote.origin.url`.chomp
    exec "open http://github.com/#{remote.split(':').last.chomp('.git')}"
  end
end

GitHub.register :info do |repo,|
  puts "== Grabbing info for #{repo}"
end
