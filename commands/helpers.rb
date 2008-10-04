helper :user_and_repo_from do |url|
  case url
  when %r|^git://github\.com/([^/]+/[^/]+)$|: $1.split('/')
  when %r|^(?:ssh://)?(?:git@)?github\.com:([^/]+/[^/]+)$|: $1.split('/')
  end
end

helper :user_and_repo_for do |remote|
  user_and_repo_from(url_for(remote))
end

helper :user_for do |remote|
  user_and_repo_for(remote).try.first
end

helper :repo_for do |remote|
  user_and_repo_for(remote).try.last
end

helper :project do
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

helper :url_for do |remote|
  `git config --get remote.#{remote}.url`.chomp
end

helper :remotes do
  regexp = '^remote\.(.+)\.url$'
  `git config --get-regexp '#{regexp}'`.split("\n").inject({}) do |memo, line|
    name_string, url = line.split(/ /, 2)
    m, name = *name_string.match(/#{regexp}/)
    memo[name.to_sym] = url
    memo
  end
end

helper :remote_branches_for do |user|
  `git ls-remote -h #{user} 2> /dev/null`.split(/\n/).inject({}) do |memo, line|
    hash, head = line.split(/\t/, 2)
    head = head[%r{refs/heads/(.+)$},1] unless head.nil?
    memo[head] = hash unless head.nil?
    memo
  end if !(user.nil? || user.strip.empty?)
end

helper :remote_branch? do |user, branch|
  remote_branches_for(user).key?(branch)
end

helper :branch_dirty? do
  # see if there are any cached or tracked files that have been modified
  # originally, we were going to use git-ls-files but that could only
  # report modified track files...not files that have been staged
  # for committal
  !(system("git diff --quiet 2>/dev/null") or !system("git diff --cached --quiet 2>/dev/null"))
end

helper :tracking do
  remotes.inject({}) do |memo, (name, url)|
    if ur = user_and_repo_from(url)
      memo[name] = ur.first
    else
      memo[name] = url
    end
    memo
  end
end

helper :tracking? do |user|
  tracking.values.include?(user)
end

helper :owner do
  user_for(:origin)
end

helper :user_and_branch do
  raw_branch = `git rev-parse --symbolic-full-name HEAD`.chomp.sub(/^refs\/heads\//, '')
  user, branch = raw_branch.split(/\//, 2)
  if branch
    [user, branch]
  else
    [owner, user]
  end
end

helper :branch_user do
  user_and_branch.first
end

helper :branch_name do
  user_and_branch.last
end

helper :public_url_for_user_and_repo do |user, repo|
  "git://github.com/#{user}/#{repo}.git"
end

helper :private_url_for_user_and_repo do |user, repo|
  "git@github.com:#{user}/#{repo}.git"
end

helper :public_url_for do |user|
  public_url_for_user_and_repo user, project
end

helper :private_url_for do |user|
  private_url_for_user_and_repo user, project
end

helper :homepage_for do |user, branch|
  "https://github.com/#{user}/#{project}/tree/#{branch}"
end

helper :network_page_for do |user|
  "https://github.com/#{user}/#{project}/network"
end

helper :has_launchy? do |blk|
  begin
    gem 'launchy'
    require 'launchy'
    blk.call
  rescue Gem::LoadError
    STDERR.puts "Sorry, you need to install launchy: `gem install launchy`"
  end
end

helper :open do |url|
  has_launchy? proc {
    Launchy::Browser.new.visit url
  }
end

