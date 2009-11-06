require 'rubygems'
require 'rake'

begin
  require 'echoe'

  Echoe.new('github', '0.4.0') do |p|
    p.rubyforge_name = 'github'
    p.summary      = "The official `github` command line helper for simplifying your GitHub experience."
    p.description  = "The official `github` command line helper for simplifying your GitHub experience."
    p.url          = "http://github.com/"
    p.author       = ['Chris Wanstrath', 'Kevin Ballard', 'Scott Chacon']
    p.email        = "chris@ozmm.org"
    p.dependencies = [
      "text-format >=1.0.0",
      "highline ~>1.5.1"
    ]
  end

rescue LoadError => boom
  puts "You are missing a dependency required for meta-operations on this gem."
  puts "#{boom.to_s.capitalize}."
end

# add spec tasks, if you have rspec installed
begin
  require 'spec/rake/spectask'

  Spec::Rake::SpecTask.new("spec") do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['--color']
  end

  task :test do
    Rake::Task['spec'].invoke
  end

  Spec::Rake::SpecTask.new("rcov_spec") do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['--color']
    t.rcov = true
    t.rcov_opts = ['--exclude', '^spec,/gems/']
  end
end
