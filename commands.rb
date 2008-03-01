GitHub.helper :user_and_project_for do |remote|
  url_for(remote).split(/[:\/]/, 2).last.split('/')
end

GitHub.helper :user_for do |remote|
  user_and_project_for(remote).first
end

GitHub.helper :project do
  user_and_project_for(:origin).last.chomp('.git')
end

GitHub.helper :url_for do |remote|
  `git config --get remote.#{remote}.url`.chomp
end

GitHub.helper :current_user do
  user_for(:origin)
end

GitHub.helper :public_url_for do |user|
  "git://github.com/#{user}/#{project}.git"
end

GitHub.register :open do 
  if helper.project
    exec "open https://github.com/#{helper.current_user}/#{helper.project}"
  end
end

GitHub.register :status do
  puts "== Status right now for #{helper.project}"
  puts "You are #{helper.current_user}"
end

GitHub.register :info do |repo, dude|
  puts "== Grabbing info for #{repo} #{dude}"
end

GitHub.describe :pull => 'hi, this is github pull'
GitHub.register :pull do |user, branch|
  branch ||= 'master'
  value    = git "remote show #{user}"

  if value.error? && value =~ /no such remote/i
    git "remote add #{user} #{helper.public_url_for(user)}"
  elsif value.error?
    die "Error: #{value}"
  end

  puts "Switching to #{user}/#{branch}"

  if git("checkout -b #{user}/#{branch}").error? && (checkout = git "checkout #{user}/#{branch}").error?
    puts checkout
    return
  end

  pgit "pull #{user} #{branch}"
end
