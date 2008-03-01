GitHub.helper :user_and_repo_from do |url|
  case url
  when %r|^git://github\.com/(.*)$|: $1.split('/')
  when %r|^git@github\.com:(.*)$|: $1.split('/')
  end
end

GitHub.helper :user_and_repo_for do |remote|
  user_and_repo_from(url_for(remote))
end

GitHub.helper :user_for do |remote|
  user_and_repo_for(remote).first
end

GitHub.helper :repo_for do |remote|
  user_and_repo_for(remote).last
end

GitHub.helper :project do
  repo_for(:origin).chomp('.git')
end

GitHub.helper :url_for do |remote|
  `git config --get remote.#{remote}.url`.chomp
end

GitHub.helper :tracking do
  `git config --get-regexp '^remote\..+\.url$'`.split(/\n/).map do |line|
    _, url = line.split(/ /, 2)
    if ur = user_and_repo_from(url)
      ur.first
    else
      "#{url} [foreign]"
    end
  end
end

GitHub.helper :tracking? do |user|
  tracking.include?(user)
end

GitHub.helper :current_user do
  user_for(:origin)
end

GitHub.helper :public_url_for do |user|
  "git://github.com/#{user}/#{project}.git"
end
