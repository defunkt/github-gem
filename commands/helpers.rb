GitHub.helper :user_and_repo_from do |url|
  case url
  when %r|^git://github\.com/([^/]+/[^/]+)$|: $1.split('/')
  when %r|^(?:ssh://)?(?:git@)?github\.com:([^/]+/[^/]+)$|: $1.split('/')
  end
end

GitHub.helper :user_and_repo_for do |remote|
  user_and_repo_from(url_for(remote))
end

GitHub.helper :user_for do |remote|
  user_and_repo_for(remote).try.first
end

GitHub.helper :repo_for do |remote|
  user_and_repo_for(remote).try.last
end

GitHub.helper :project do
  repo = repo_for(:origin)
  if repo.nil?
    if url_for(:origin) == ""
      STDERR.puts "Error: missing remote 'origin'"
    else
      STDERR.puts "Error: remote 'origin' is not a github URL"
    end
    exit 1
  end
  repo.chomp('.git')
end

GitHub.helper :url_for do |remote|
  `git config --get remote.#{remote}.url`.chomp
end

GitHub.helper :remotes do
  regexp = '^remote\.(.+)\.url$'
  `git config --get-regexp '#{regexp}'`.split(/\n/).inject({}) do |memo, line|
    name_string, url = line.split(/ /, 2)
    m, name = *name_string.match(/#{regexp}/)
    memo[name.to_sym] = url
    memo
  end
end

GitHub.helper :tracking do
  remotes.inject({}) do |memo, (name, url)|
    if ur = user_and_repo_from(url)
      memo[name] = ur.first
    else
      memo[name] = url
    end
    memo
  end
end

GitHub.helper :tracking? do |user|
  tracking.values.include?(user)
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

GitHub.helper :private_url_for do |user|
  "git@github.com:#{user}/#{project}.git"
end

GitHub.helper :homepage_for do |user, branch|
  "https://github.com/#{user}/#{project}/tree/#{branch}"
end

GitHub.helper :network_page_for do |user|
  "https://github.com/#{user}/#{project}/network"
end

GitHub.helper :open do
  ENV['BROWSER'] || (Windoze ? 'start' : 'open')
end
