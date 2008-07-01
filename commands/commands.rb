desc "Open this repo's master branch in a web browser."
command :home do |user|
  if helper.project
    helper.open helper.homepage_for(user || helper.owner, 'master')
  end
end

desc "Open this repo in a web browser."
command :browse do |user, branch|
  if helper.project
    # if one arg given, treat it as a branch name
    # unless it maches user/branch, then split it
    # if two args given, treat as user branch
    # if no args given, use defaults
    user, branch = user.split("/", 2) if branch.nil? unless user.nil?
    branch = user and user = nil if branch.nil?
    user ||= helper.branch_user
    branch ||= helper.branch_name
    helper.open helper.homepage_for(user, branch)
  end
end

desc "Open the network page for this repo in a web browser."
command :network do |user|
  if helper.project
    user ||= helper.owner
    helper.open helper.network_page_for(user)
  end
end

desc "Info about this project."
command :info do
  puts "== Info for #{helper.project}"
  puts "You are #{helper.owner}"
  puts "Currently tracking:"
  helper.tracking.sort { |(a,),(b,)| a == :origin ? -1 : b == :origin ? 1 : a.to_s <=> b.to_s }.each do |(name,user_or_url)|
    puts " - #{user_or_url} (as #{name})"
  end
end

desc "Track another user's repository."
flags :private => "Use git@github.com: instead of git://github.com/."
flags :ssh => 'Equivalent to --private'
command :track do |remote, user|
  # track remote user
  # track remote user/repo
  # track user
  # track user/repo
  user, remote = remote, nil if user.nil?
  die "Specify a user to track" if user.nil?
  user, repo = user.split("/", 2)
  die "Already tracking #{user}" if helper.tracking?(user)
  repo = @helper.project if repo.nil?
  repo.chomp!(".git")
  remote ||= user

  if options[:private] || options[:ssh]
    git "remote add #{remote} #{helper.private_url_for_user_and_repo(user, repo)}"
  else
    git "remote add #{remote} #{helper.public_url_for_user_and_repo(user, repo)}"
  end
end

desc "Pull from a remote."
flags :merge => "Automatically merge remote's changes into your master."
command :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  user, branch = user.split("/", 2) if branch.nil?
  branch ||= 'master'
  GitHub.invoke(:track, user) unless helper.tracking?(user)
  
  if options[:merge]
    git_exec "pull #{user} #{branch}"
  else
    puts "Switching to #{user}/#{branch}"
    git "checkout #{user}/#{branch}" if git("checkout -b #{user}/#{branch}").error?
    git_exec "pull #{user} #{branch}"
  end
end

desc "Clone a repo."
flags :ssh => "Clone using the git@github.com style url."
command :clone do |user, repo, dir|
  die "Specify a user to pull from" if user.nil?
  if user.include? ?/
    die "Expected user/repo dir, given extra argument" if dir
    (user, repo), dir = [user.split('/', 2), repo]
  end
  die "Specify a repo to pull from" if repo.nil?

  if options[:ssh]
    git_exec "clone git@github.com:#{user}/#{repo}.git" + (dir ? " #{dir}" : "")
  else
    git_exec "clone git://github.com/#{user}/#{repo}.git" + (dir ? " #{dir}" : "")
  end
end

desc "Generate the text for a pull request."
command :'pull-request' do |user, branch|
  if helper.project
    die "Specify a user for the pull request" if user.nil?
    user, branch = user.split('/', 2) if branch.nil?
    branch ||= 'master'
    GitHub.invoke(:track, user) unless helper.tracking?(user)

    git_exec "request-pull #{user}/#{branch} origin"
  end
end
