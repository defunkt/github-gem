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

helper :local_heads do
  `git show-ref --heads --hash`.split("\n")
end

helper :get_commits do |rev_array|
  list = rev_array.join(' ')
  `git log --pretty=format:"%H::%ae::%s" --no-merges #{list}`.split("\n").map { |a| a.split('::') }
end

helper :get_cherry do |branch|
  `git cherry HEAD #{branch} | git name-rev --stdin`.split("\n").map { |a| a.split(' ') }
end

helper :print_commits do |cherries, commits|  
  cherries.sort! { |a, b| a[2] <=> b[2] }
  shown_commits = {}
  cherries.each do |cherry|
    status, sha, ref_name = cherry
    next if shown_commits[sha]
    ref_name = ref_name.gsub('remotes/', '')
    commit = commits.assoc(sha)
    if status == '+' && commit
      puts [sha[0,6], ref_name.ljust(25), commit[1][0,20].ljust(21), commit[2][0, 36]].join(" ")
    end
    shown_commits[sha] = true
  end
  puts 
end

helper :remotes do
  regexp = '^remote\.(.+)\.url$'
  `git config --get-regexp '#{regexp}'`.split(/\n/).inject({}) do |memo, line|
    name_string, url = line.split(/ /, 2)
    m, name = *name_string.match(/#{regexp}/)
    memo[name.to_sym] = url
    memo
  end
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

helper :network_meta_for do |user|
  "http://github.com/#{user}/#{project}/network_meta"
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

helper :print_network_cherry_help do
  puts "
=========================================================================================
These are all the commits that other people have pushed that you have not
applied or ignored yet. (see 'github ignore')  

* You can run 'github fetch user/branch' to pull one into a local branch for testing
* You can run 'git cherry-pick [SHA]' to apply a single patch
* Or, you can run 'git merge user/branch' to merge a commit and everything underneath it.
=========================================================================================

"
end

