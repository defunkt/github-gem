GitHub.helper :user_and_project_from do |url|
  case url
  when %r|^git://github\.com/(.*)$|: $1.split('/')
  when %r|^git@github\.com:(.*)$|: $1.split('/')
  end
end

GitHub.helper :user_and_project_for do |remote|
  user_and_project_from(url_for(remote))
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

GitHub.helper :following do
  `git config --get-regexp '^remote\..+\.url$'`.split(/\n/).map do |line|
    _, url = line.split(/ /, 2)
    user_and_project_from(url).first
  end
end

GitHub.helper :current_user do
  user_for(:origin)
end

GitHub.helper :public_url_for do |user|
  "git://github.com/#{user}/#{project}.git"
end

GitHub.helper :following? do |user|
  following.include?(user)
end
