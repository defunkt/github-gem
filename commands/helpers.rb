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

helper :has_commit? do |sha|
  `git show #{sha} >/dev/null 2>/dev/null`
  $?.exitstatus == 0
end

helper :resolve_commits do |treeish|
  if treeish
    if treeish.match(/\.\./)
      commits = `git rev-list #{treeish}`.split("\n")
    else
      commits = `git rev-parse #{treeish}`.split("\n")
    end
  else
    # standard in
    puts 'reading from stdin...'
    commits = $stdin.read.split("\n") 
  end
  commits.select { |a| a.size == 40 } # only the shas, not the ^SHAs
end

helper :ignore_file_path do
  dir = `git rev-parse --git-dir`.chomp
  File.join(dir, 'ignore-shas')
end

helper :ignore_sha_array do
  File.open( ignore_file_path ) { |yf| YAML::load( yf ) } rescue {}
end

helper :ignore_shas do |shas|
  ignores = ignore_sha_array
  shas.each do |sha|
    puts 'ignoring ' + sha
    ignores[sha] = true
  end
  File.open( ignore_file_path, 'w' ) do |out|
    YAML.dump( ignores, out )
  end
end

helper :get_commits do |rev_array|
  list = rev_array.select { |a| has_commit?(a) }.join(' ')
  `git log --pretty=format:"%H::%ae::%s::%ar::%ad" --no-merges #{list}`.split("\n").map { |a| a.split('::') }
end

helper :get_cherry do |branch|
  `git cherry HEAD #{branch} | git name-rev --stdin`.split("\n").map { |a| a.split(' ') }
end

helper :get_common do |branch|
  `git rev-list ..#{branch} --boundary | tail -1 | git name-rev --stdin`.split(' ')[1] rescue 'unknown'
end

helper :print_commits do |cherries, commits, options|
  ignores = ignore_sha_array
  our_commits = cherries.map { |item| c = commits.assoc(item[1]); [item, c] if c }
  
  case options[:sort]
  when 'branch'
    our_commits.sort! { |a, b| a[0][2] <=> b[0][2] }
  when 'author'
    our_commits.sort! { |a, b| a[1][1] <=> b[1][1] }
  else
    our_commits.sort! { |a, b| Date.parse(a[1][4]) <=> Date.parse(b[1][4]) }
  end
  
  shown_commits = {}
  before = Date.parse(options[:before]) if options[:before] rescue puts 'cant parse before date'
  after = Date.parse(options[:after]) if options[:after] rescue puts 'cant parse after date'
  our_commits.each do |cherry, commit|
    status, sha, ref_name = cherry
    next if shown_commits[sha] || ignores[sha]
    next if options[:project] && !ref_name.match(Regexp.new(options[:project]))
    ref_name = ref_name.gsub('remotes/', '')
    if status == '+' && commit
      next if options[:author] && !commit[1].match(Regexp.new(options[:author]))
      next if options[:before] && before && (before < Date.parse(commit[4])) 
      next if options[:after] && after && (after > Date.parse(commit[4])) 
      next if options[:applies] && !applies_cleanly(sha)
      if options[:shas]
        puts sha
      else
        common = options[:common] ? get_common(sha) : ''
        puts [sha[0,6], ref_name.ljust(25), commit[1][0,20].ljust(21), 
            commit[2][0, 36].ljust(38), commit[3], common].join(" ")
      end
    end
    shown_commits[sha] = true
  end
end

helper :applies_cleanly do |sha|
  `git diff ...#{sha} | git apply --check >/dev/null 2>/dev/null`
  $?.exitstatus == 0
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

helper :print_network_help do
  puts "
You have to provide a command :

    web [user]     - opens your web browser to the network graph page for this
                     project, or for the graph page for [user] if provided
                 
    list           - shows the projects in your network that have commits
                     that you have not pulled in yet, and branch names 
                     
    fetch          - adds all projects in your network as remotes and fetches
                     any objects from them that you don't have yet
  
    commits        - will show you a list of all commits in your network that
                     you have not ignored or have not merged or cherry-picked.
                     This will automatically fetch objects you don't have yet.
                   
      --project (user/branch)  - only show projects that match string
      --author (email)         - only show projects that match string
      --after (date)           - only show commits after date
      --before (date)          - only show commits before date
      --shas                   - only print shas (can pipe through 'github ignore')
      --applies                - filter to patches that still apply cleanly
      --sort                   - how to sort the commits (date, branch, author)
"
end

helper :print_network_cherry_help do
  puts "
=========================================================================================
These are all the commits that other people have pushed that you have not
applied or ignored yet (see 'github ignore'). Some things you might want to do:

* You can run 'github fetch user/branch' (sans '~N') to pull into a local branch for testing
* You can run 'git cherry-pick [SHA]' to apply a single patch
* You can run 'git merge user/branch' to merge a commit and all the '~N' variants.
* You can ignore all of a projects commits with 'github ignore ..user/branch'
=========================================================================================

"
end

