GitHub.helper :project do
  `git config --get remote.origin.url`.chomp.split('/').last.chomp('.git')
end

GitHub.register :open do 
  if remote = `git config -l`.split("\n").detect { |line| line =~ /remote.origin.url/ }
    exec "open http://github.com/#{remote.split(':').last.chomp('.git')}"
  end
end

GitHub.register :info do |repo, dude|
  puts "== Grabbing info for #{repo} #{dude}"
end

GitHub.register :pull do |user, branch|
  branch ||= 'master'
  value    = git "remote show #{user}"

  if value.error? && value =~ /no such remote/i
    git "remote add #{user} git://github.com/#{user}/#{helper.project}.git"
  elsif value.error?
    die "Error: #{value}"
  end

  git "checkout -b #{user}/#{branch}"
  git "pull #{user} #{branch}"
end
