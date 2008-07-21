desc "Open the given user's gist.github.com homepage in the web browser"
command :home do |user|
  if user
    url = helper.homepage_for(user)
  else
    url = helper.homepage
  end
  helper.open url
end
