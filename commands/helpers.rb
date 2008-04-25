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

GitHub.helper :remotes do
  regexp = '^remote\.(.+)\.url$'
  `git config --get-regexp '#{regexp}'`.split(/\n/).map do |line|
    name_string, url = line.split(/ /, 2)
    m, name = *name_string.match(/#{regexp}/)
    [name, url]
  end
end

GitHub.helper :tracking do
  remotes.map do |(name, url)|
    if ur = user_and_repo_from(url)
      [name, ur.first]
    else
      [name, url]
    end
  end
end

GitHub.helper :tracking? do |user|
  tracking.include?(user)
end

GitHub.helper :owner do
  user_for(:origin)
end

GitHub.helper :user_and_branch do
  raw_branch = `git rev-parse --symbolic-full-name HEAD`.chomp.sub(/^refs\/heads\//, '')
  user, branch = raw_branch.split(/\//, 2)
  if branch
    [user, branch]
  else
    [owner, user]
  end
end

GitHub.helper :branch_user do
  user_and_branch.first
end

GitHub.helper :branch_name do
  user_and_branch.last
end

GitHub.helper :public_url_for do |user|
  "git://github.com/#{user}/#{project}.git"
end

GitHub.helper :homepage_for do |user, branch|
  "https://github.com/#{user}/#{project}/tree/#{branch}"
end

GitHub.helper :open do
  WINDOZE ? 'start' : 'open'
end
    