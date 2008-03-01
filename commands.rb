GitHub.register :open do 
  if helper.project
    exec "open https://github.com/#{helper.current_user}/#{helper.project}"
  end
end

GitHub.register :info do
  puts "== Info for #{helper.project}"
  puts "You are #{helper.current_user}"
  puts "Currently tracking: "
  helper.tracking.each do |(name,user_or_url)|
    puts " - #{user_or_url} (as #{name})"
  end
end

GitHub.register :track do |user|
  die "Specify a user to track" if user.nil?
  die "Already tracking #{user}" if helper.tracking?(user)

  git "remote add #{user} #{helper.public_url_for(user)}"
end

GitHub.describe :pull => 'hi, this is github pull'
GitHub.register :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  GitHub.invoke(:track, user) unless helper.tracking?(user)
  branch ||= 'master'

  puts "Switching to #{user}/#{branch}"

  if git("checkout -b #{user}/#{branch}").error? && (checkout = git "checkout #{user}/#{branch}").error?
    puts checkout
    return
  end

  pgit "pull #{user} #{branch}"
end
