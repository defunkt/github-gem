desc "Open this repo's master branch in a web browser."
command :home do |user|
  if helper.project
    homepage = helper.homepage_for(user || helper.owner, 'master')
    homepage.gsub!(%r{/tree/master$}, '')
    helper.open homepage
  end
end

desc "Open this repo's Admin panel a web browser."
command :admin do |user|
  if helper.project
    homepage = helper.homepage_for(user || helper.owner, 'master')
    homepage.gsub!(%r{/tree/master$}, '')
    homepage += "/admin"
    helper.open homepage
  end
end

desc "Automatically set configuration info, or pass args to specify."
usage "github config [my_username] [my_repo_name]"
command :config do |user, repo|
  user ||= "#{github_user}"
  repo ||= File.basename(FileUtils.pwd)
  git "config --global github.user #{user}"
  git "config github.repo #{repo}"
  puts "Configured with github.user #{user}, github.repo #{repo}"
end

desc "Open this repo in a web browser."
usage "github browse [user] [branch]"
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

desc 'Open the given user/project in a web browser'
usage 'github open [user/project]'
command :open do |arg|
  helper.open "https://github.com/#{arg}"
end

desc "Info about this project."
command :info do
  puts "== Info for #{helper.project}"
  puts "You are #{helper.owner}"
  puts "Currently tracking:"
  helper.tracking.sort { |a, b| a == helper.origin ? -1 : b == helper.origin ? 1 : a.to_s <=> b.to_s }.each do |(name,user_or_url)|
    puts " - #{user_or_url} (as #{name})"
  end
end

desc "Track another user's repository."
usage "github track remote [user]"
usage "github track remote [user/repo]"
usage "github track [user]"
usage "github track [user/repo]"
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

desc "Fetch all refs from a user"
command :fetch_all do |user|
  GitHub.invoke(:track, user) unless helper.tracking?(user)
  git "fetch #{user}"
end

desc "Fetch from a remote to a local branch."
command :fetch do |user, branch|
  die "Specify a user to pull from" if user.nil?
  user, branch = user.split("/", 2) if branch.nil?
  branch ||= 'master'
  GitHub.invoke(:track, user) unless helper.tracking?(user)

  die "Unknown branch (#{branch}) specified" unless helper.remote_branch?(user, branch)
  die "Unable to switch branches, your current branch has uncommitted changes" if helper.branch_dirty?

  puts "Fetching #{user}/#{branch}"
  git "fetch #{user} #{branch}:refs/remotes/#{user}/#{branch}"
  git "update-ref refs/heads/#{user}/#{branch} refs/remotes/#{user}/#{branch}"
  git_exec "checkout #{user}/#{branch}"
end

desc "Pull from a remote."
usage "github pull [user] [branch]"
flags :merge => "Automatically merge remote's changes into your master."
command :pull do |user, branch|
  die "Specify a user to pull from" if user.nil?
  user, branch = user.split("/", 2) if branch.nil?

  # if !helper.network_members(user, {}).include?(user)
  #   git_exec "#{helper.argv.join(' ')}".strip
  #   return
  # end

  branch ||= 'master'
  GitHub.invoke(:track, user) unless helper.tracking?(user)

  die "Unable to switch branches, your current branch has uncommitted changes" if helper.branch_dirty?

  if options[:merge]
    git_exec "pull #{user} #{branch}"
  else
    puts "Switching to #{user}-#{branch}"
    git "fetch #{user}"
    git_exec "checkout -b #{user}/#{branch} #{user}/#{branch}"
  end
end

desc "Clone a repo. Uses ssh if current user is "
usage "github clone [user] [repo] [dir]"
flags :ssh => "Clone using the git@github.com style url."
flags :search => "Search for [user|repo] and clone selected repository"
command :clone do |user, repo, dir|
  die "Specify a user to pull from" if user.nil?
  if options[:search]
    query = [user, repo, dir].compact.join(" ")
    data = JSON.parse(open("https://github.com/api/v1/json/search/#{URI.escape query}").read)
    if (repos = data['repositories']) && !repos.nil? && repos.length > 0
      repo_list = repos.map do |r|
        { "name" => "#{r['username']}/#{r['name']}", "description" => r['description'] }
      end
      formatted_list = helper.format_list(repo_list).split("\n")
      if user_repo = GitHub::UI.display_select_list(formatted_list)
        user, repo = user_repo.strip.split('/', 2)
      end
    end
    die "Perhaps try another search" unless user && repo
  end

  if user.include?('/') && !user.include?('@') && !user.include?(':')
    die "Expected user/repo dir, given extra argument" if dir
    (user, repo), dir = [user.split('/', 2), repo]
  end

  if repo
    if options[:ssh] || current_user?(user)
      git_exec "clone git@github.com:#{user}/#{repo}.git" + (dir ? " #{dir}" : "")
    else
      git_exec "clone git://github.com/#{user}/#{repo}.git" + (dir ? " #{dir}" : "")
    end
  else
    git_exec "#{helper.argv.join(' ')}".strip
  end
end

desc "Generate the text for a pull request."
usage "github pull-request [user] [branch]"
command :'pull-request' do |user, branch|
  if helper.project
    die "Specify a user for the pull request" if user.nil?
    user, branch = user.split('/', 2) if branch.nil?
    branch ||= 'master'
    GitHub.invoke(:track, user) unless helper.tracking?(user)

    git_exec "request-pull #{user}/#{branch} #{helper.origin}"
  end
end

desc "Create a new, empty GitHub repository"
usage "github create [repo]"
flags :markdown => 'Create README.markdown'
flags :mdown => 'Create README.mdown'
flags :textile => 'Create README.textile'
flags :rdoc => 'Create README.rdoc'
flags :rst => 'Create README.rst'
flags :private => 'Create private repository'
command :create do |repo|
  command = "curl -F 'name=#{repo}' -F 'public=#{options[:private] ? 0 : 1}' -F 'login=#{github_user}' -F 'token=#{github_token}' https://github.com/api/v2/json/repos/create"
  output_json = sh command
  output = JSON.parse(output_json)
  if output["error"]
    die output["error"]
  else
    mkdir repo
    cd repo
    git "init"
    extension = options.keys.first
    touch extension ? "README.#{extension}" : "README"
    git "add *"
    git "commit -m 'First commit!'"
    git "remote add origin git@github.com:#{github_user}/#{repo}.git"
    git_exec "push origin master"
  end
end

desc "Forks a GitHub repository"
usage "github fork"
usage "github fork [user]/[repo]"
command :fork do |user, repo|
  if repo.nil?
    if user
      user, repo = user.split('/')
    else
      unless helper.remotes.empty?
        is_repo = true
        user = helper.owner
        repo = helper.project
      else
        die "Specify a user/project to fork, or run from within a repo"
      end
    end
  end

  current_origin = git "config remote.origin.url"
  
  url = "https://github.com/api/v2/json/repos/fork/#{user}/#{repo}"
  output_json = sh "curl -F 'login=#{github_user}' -F 'token=#{github_token}' #{url}"
  output = JSON.parse(output_json)
  if output["error"]
    die output["error"]
  else
    url = "git@github.com:#{github_user}/#{repo}.git"
    if is_repo
      git "config remote.origin.url #{url}"
      git "config remote.upstream.url #{current_origin}"
      puts "#{user}/#{repo} forked"
    else
      puts "Giving GitHub a moment to create the fork..."
      sleep 3
      git_exec "clone #{url}"
    end
  end
end

# TODO organizations

desc "Create a new GitHub repository from the current local repository"
usage "github create-from-local [repo_name]"
flags :private => 'Create private repository'
command :'create-from-local' do |repo_name|
  cwd = sh "pwd"
  if repo_name.nil?
    repo = File.basename(cwd)
  else
    repo = repo_name
  end
  is_repo = !git("status").match(/fatal/)
  raise "Not a git repository. Use 'gh create' instead" unless is_repo

  # trying to force the organization
  organization = nil
  if organization
    url = "https://api.github.com/orgs/#{organization}/repos"
    repo_owner = organization
  else
    url = "https://api.github.com/user/repos"
    repo_owner = github_user
  end
  p url
  github_password = 'XXX'
  command = "curl -F 'name=#{repo}' -F 'private=#{options[:private] ? true : false}' -u '#{github_user}:#{github_password}' #{url}"
  puts command
  output_json = sh command
  puts output_json
  begin
    output = JSON.parse(output_json)
    if output["error"] || output["message"]
      puts output["message"]
      p output["errors"] if output["errors"]
      exit 1
    else
      git "remote add origin git@github.com:#{github_user}/#{repo}.git"
      git_exec "push origin master"
    end
  rescue JSON::ParserError
    die "JSON wasn't returned. My guess is the repo wasn't created."
  end
end

desc "Delete this fork, or the entire repo if not a fork (with ask for confirm)"
usage "github delete"
flags :confirm => "Force config to challenge"
command :delete do
  repo_url  = git "config remote.origin.url"
  upstream  = git "config remote.upstream.url"
  repo_type = upstream == "" ? "main" : "fork"
  if repo_url == ""
    die "No 'origin' repo url to delete."
  end
  if options[:confirm] || highline.agree("Really delete #{repo_type} repo #{repo_url}? [yN]")
    # delete the repo
    user, repo = helper.user_and_repo_from repo_url
    repo.gsub!(/\.git$/, "")
    url = "https://github.com/api/v2/json/repos/delete/#{user}/#{repo}"
    command = "curl -F 'login=#{github_user}' -F 'token=#{github_token}' #{url}"
    p command
    output_json = sh command
    output = JSON.parse(output_json)
    if output["error"]
      die output["error"]
    else
      p output
      git "remote rm origin"
      if repo_type == "fork"
        puts "Restoring upstream #{upstream} to origin"
        git "config remote.origin.url #{upstream}"
      end
    end
  end
end

desc "Search GitHub for the given repository name."
usage "github search [query]"
command :search do |query|
  die "Usage: github search [query]" if query.nil?
  data = JSON.parse(open("https://github.com/api/v1/json/search/#{URI.escape query}").read)
  if (repos = data['repositories']) && !repos.nil? && repos.length > 0
    puts repos.map { |r| "#{r['username']}/#{r['name']}"}.sort.uniq
  else
    puts "No results found"
  end
end
