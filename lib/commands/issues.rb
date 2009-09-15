desc "Project issues tools - sub-commands : open [user], closed [user]"
flags :user => "Show issues from a certain user's repository"
flags :after => "Only show issues updated after a certain date"
flags :label => "Only show issues with a certain label"
command :issues do |command|
  return if !helper.project
  options[:user] ||= helper.owner

  case command
  when 'open', 'closed'
    report = YAML.load(Kernel.open(@helper.list_issues_for(options[:user], command)))
    @helper.print_issues(report['issues'], options)
  else
    helper.print_issues_help
  end
end
