# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{github}
  s.version = "0.3.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Wanstrath, Kevin Ballard, Scott Chacon"]
  s.date = %q{2009-11-04}
  s.description = %q{The official `github` command line helper for simplifying your GitHub experience.}
  s.email = %q{chris@ozmm.org}
  s.executables = ["gh", "github"]
  s.extra_rdoc_files = ["LICENSE", "README", "bin/gh", "bin/github", "lib/commands/commands.rb", "lib/commands/helpers.rb", "lib/commands/issues.rb", "lib/commands/network.rb", "lib/github.rb", "lib/github/command.rb", "lib/github/extensions.rb", "lib/github/helper.rb", "lib/github/ui.rb"]
  s.files = ["History.txt", "LICENSE", "Manifest", "README", "Rakefile", "bin/gh", "bin/github", "github.gemspec", "lib/commands/commands.rb", "lib/commands/helpers.rb", "lib/commands/issues.rb", "lib/commands/network.rb", "lib/github.rb", "lib/github/command.rb", "lib/github/extensions.rb", "lib/github/helper.rb", "lib/github/ui.rb", "setup.rb", "spec/command_spec.rb", "spec/extensions_spec.rb", "spec/github_spec.rb", "spec/helper_spec.rb", "spec/spec_helper.rb", "spec/ui_spec.rb", "spec/windoze_spec.rb"]
  s.homepage = %q{http://github.com/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Github", "--main", "README"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{github}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{The official `github` command line helper for simplifying your GitHub experience.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<text-format>, [">= 0"])
    else
      s.add_dependency(%q<text-format>, [">= 0"])
    end
  else
    s.add_dependency(%q<text-format>, [">= 0"])
  end
end
