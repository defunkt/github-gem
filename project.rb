module GitHub
  class Project
    def name
      @name ||= `git config --get remote.origin.url`.chomp.split('/').last.chomp('.git')
    end
  end
end
