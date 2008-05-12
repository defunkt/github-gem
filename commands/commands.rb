GitHub.register :helper do |name, comma_args|
  comma_args ||= ''
  puts helper.send(name, comma_args.split(/,/))
end

GitHub.describe :home => "Open this repo's master branch in a web browser."
GitHub.register :home do
  if helper.project
    exec "#{helper.open} #{helper.homepage_for(helper.owner, 'master')}"
  end
end

GitHub.describe :browse => "Open this repo in a web browser."
GitHub.register :browse do
  if helper.project
    exec "#{helper.open} #{helper.homepage_for(helper.branch_user, helper.branch_name)}"
  end
end

GitHub.describe :info => "Info about this project."
GitHub.register :info do
  puts "== Info for #{helper.project}"
  puts "You are #{helper.owner}"
  puts "Currently tracking: "
  helper.tracking.each do |(name,user_or_url)|
    puts " - #{user_or_url} (as #{name})"
  end
end

GitHub.describe :track => "Track another user's repository. Pass --private to track a private project."
GitHub.register :track do |user|
  die "Specify a user to track" if user.nil?
  die "Already tracking #{user}" if helper.tracking?(user)

  if options[:private]
    git "remote add #{user} #{helper.private_url_for(user)}"
  else
    git "remote add #{user} #{helper.public_url_for(user)}"
  end
end

GitHub.describe :pull => "Pull from a remote.  Pass --merge to automatically merge remote's changes into your master."
GitHub.register :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  GitHub.invoke(:track, user) unless helper.tracking?(user)
  branch ||= 'master'

  puts "Switching to #{user}/#{branch}"
  git "checkout #{user}/#{branch}" if git("checkout -b #{user}/#{branch}").error? 
  
  if options[:merge]
    git "pull #{user} #{branch}"
    git "checkout master"
    git_exec "merge #{user}/#{branch}"
  else
    git_exec "pull #{user} #{branch}"
  end
end

GitHub.describe :clone => "Clone a repo.  Pass --ssh to clone from your own git@github.com schema."
GitHub.register :clone do |user, repo|
  user, repo = user.split('/') unless repo
  die "Specify a repo to pull from" if repo.nil?

  if options[:ssh]
    git_exec "clone git@github.com:#{user}/#{repo}.git"
  else
    git_exec "clone git://github.com/#{user}/#{repo}.git"
  end
end
