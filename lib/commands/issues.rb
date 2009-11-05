desc "Project issues tools - sub-commands : open [user], closed [user]"
flags :after => "Only show issues updated after a certain date"
flags :label => "Only show issues with a certain label"
command :issues do |command, user|
  return if !helper.project
  user ||= helper.owner

  case command
  when 'open', 'closed'
    report = YAML.load(open(@helper.list_issues_for(user, command)))
    @helper.print_issues(report['issues'], options)
  when 'web'
    helper.open helper.issues_page_for(user)
  else
    helper.print_issues_help
  end
end
