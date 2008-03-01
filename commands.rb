GitHub.register :open do 
  if helper.project
    exec "open https://github.com/#{helper.current_user}/#{helper.project}"
  end
end

GitHub.register :info do
  puts "== Info for #{helper.project}"
  puts "You are #{helper.current_user}"
  puts "Currently following: "
  helper.following.each do |user|
    puts " - #{user}"
  end
end

GitHub.register :follow do |user|
  die "Specify a user to pull from" if user.nil?
  die "Already following #{user}" if helper.following?(user)

  git "remote add #{user} #{helper.public_url_for(user)}"
end

GitHub.describe :pull => 'hi, this is github pull'
GitHub.register :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  GitHub.invoke(:follow, user) unless helper.following?(user)
  branch ||= 'master'

  puts "Switching to #{user}/#{branch}"

  if git("checkout -b #{user}/#{branch}").error? && (checkout = git "checkout #{user}/#{branch}").error?
    puts checkout
    return
  end

  pgit "pull #{user} #{branch}"
end
