GitHub.helper :project do
  `git config --get remote.origin.url`.chomp.split('/').last.chomp('.git')
end

GitHub.register :open do 
  if remote = `git config --get remote.origin.url`.chomp
    exec "open http://github.com/#{remote.split(':').last.chomp('.git')}"
  end
end

GitHub.register :info do |repo, dude|
  puts "== Grabbing info for #{repo} #{dude}"
end

GitHub.register :pull do |user, branch|
  branch ||= 'master'
  if `git remote show #{user}` =~ /no such remote/i
    `git remote add #{user} git://github.com/#{user}/#{helper.project}.git`
  end
end
