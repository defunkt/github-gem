GitHub.register :helper do |name, comma_args|
  comma_args ||= ''
  puts helper.send(name, comma_args.split(/,/))
end

GitHub.describe :home => "Open this repo's master branch in a web browser."
GitHub.register :home do
  if helper.project
    exec "open #{helper.homepage_for(helper.owner, 'master')}"
  end
end

GitHub.describe :browse => "Open this repo in a web browser."
GitHub.register :browse do
  if helper.project
    exec "open #{helper.homepage_for(helper.branch_user, helper.branch_name)}"
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

GitHub.describe :track => "Track another user's repository."
GitHub.register :track do |user|
  die "Specify a user to track" if user.nil?
  die "Already tracking #{user}" if helper.tracking?(user)

  git "remote add #{user} #{helper.public_url_for(user)}"
end

GitHub.describe :pull => 'Pull from a remote.'
GitHub.register :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  GitHub.invoke(:track, user) unless helper.tracking?(user)
  branch ||= 'master'

  puts "Switching to #{user}/#{branch}"

  if git("checkout -b #{user}/#{branch}").error? && (checkout = git "checkout #{user}/#{branch}").error?
    puts checkout
    puts :error
    return
  end

  pgit "pull #{user} #{branch}"
end
