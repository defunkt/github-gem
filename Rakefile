require 'rubygems'
require 'rake'

begin
  require 'echoe'

  Echoe.new('github', '0.1.3') do |p|
    p.rubyforge_name = 'github'
    p.summary      = "The official `github` command line helper for simplifying your GitHub experience."
    p.description  = "The official `github` command line helper for simplifying your GitHub experience."
    p.url          = "http://github.com/"
    p.author       = ['Chris Wanstrath', 'Kevin Ballard']
    p.email        = "chris@ozmm.org"
    # p.dependencies = ["launchy"]
  end

rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end

# add spec tasks, if you have rspec installed
begin
  require 'spec/rake/spectask'

  def spec_task(cmd=nil, rcov=false)
    name = "spec"
    name << ":rcov" if rcov
    root_name = name.dup
    cmd ||= "shared"
    name << ":#{cmd}"
    desc ''
    Spec::Rake::SpecTask.new(name) do |t|
      t.spec_files = FileList["spec#{"/#{cmd}" if cmd}/*_spec.rb"]
      t.spec_opts = ['--color']
      if rcov
        t.rcov = true
        t.rcov_opts = ['--exclude', '^spec,/gems/']
      end
    end
    task root_name => name
    spec_task cmd, true unless rcov
  end

  desc 'Run specs'
  task :spec
  desc 'Run specs using RCov'
  task :'spec:shared'

  spec_task
  spec_task 'github'
end
