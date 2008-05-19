GitHub.register :helper do |name, comma_args|
  comma_args ||= ''
  puts helper.send(name, comma_args.split(/,/))
end

GitHub.describe :home => "Open this repo's master branch in a web browser."
GitHub.register :home do |user|
  if helper.project
    exec "#{helper.open} #{helper.homepage_for(user || helper.owner, 'master')}"
  end
end

GitHub.describe :browse => "Open this repo in a web browser."
GitHub.register :browse do |user, branch|
  if helper.project
    # if one arg given, treat it as a branch name
    # unless it maches user/branch, then split it
    # if two args given, treat as user branch
    # if no args given, use defaults
    user, branch = user.split("/", 2) if branch.nil? unless user.nil?
    branch = user and user = nil if branch.nil?
    user ||= helper.branch_user
    branch ||= helper.branch_name
    exec "#{helper.open} #{helper.homepage_for(user, branch)}"
  end
end

GitHub.describe :network => "Open the network page for this repo in a web browser"
GitHub.register :network do |user|
  if helper.project
    user ||= helper.owner
    exec "#{helper.open} #{helper.network_page_for(user)}"
  end
end

GitHub.describe :info => "Info about this project."
GitHub.register :info do
  puts "== Info for #{helper.project}"
  puts "You are #{helper.owner}"
  puts "Currently tracking:"
  helper.tracking.each do |(name,user_or_url)|
    puts " - #{user_or_url} (as #{name})"
  end
end

GitHub.describe :track => "Track another user's repository."
GitHub.flags    :track, :private => "Use git@github.com: instead of git://github.com/"
GitHub.register :track do |user|
  die "Specify a user to track" if user.nil?
  die "Already tracking #{user}" if helper.tracking?(user)

  if options[:private]
    git "remote add #{user} #{helper.private_url_for(user)}"
  else
    git "remote add #{user} #{helper.public_url_for(user)}"
  end
end

GitHub.describe :pull => "Pull from a remote."
GitHub.flags    :pull, :merge => "Automatically merge remote's changes into your master."
GitHub.register :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  GitHub.invoke(:track, user) unless helper.tracking?(user)
  branch ||= 'master'
  
  if options[:merge]
    git_exec "pull #{user} #{branch}"
  else
    puts "Switching to #{user}/#{branch}"
    git "checkout #{user}/#{branch}" if git("checkout -b #{user}/#{branch}").error?
    git_exec "pull #{user} #{branch}"
  end
end

GitHub.describe :clone => "Clone a repo."
GitHub.flags    :clone, :ssh => "Clone using the git@github.com style url"
GitHub.register :clone do |user, repo|
  user, repo = user.split('/') unless repo
  die "Specify a repo to pull from" if repo.nil?

  if options[:ssh]
    git_exec "clone git@github.com:#{user}/#{repo}.git"
  else
    git_exec "clone git://github.com/#{user}/#{repo}.git"
  end
end
