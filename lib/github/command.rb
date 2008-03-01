module GitHub
  class Command
    def initialize(block)
      @block = block
    end

    def call(*args)
      arity = @block.arity
      args << nil while args.size < arity
      @block.call(*args)
    end
    
    def helper
      @helper ||= Helper.new
    end
  end
end
