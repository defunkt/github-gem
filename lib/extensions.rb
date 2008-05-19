# define #try
class Object
  def try
    self
  end
end

class NilClass
  klass = Class.new
  klass.class_eval do
    instance_methods.each { |meth| undef_method meth.to_sym unless meth =~ /^__(id|send)__$/ }
    def method_missing(*args)
      nil
    end
  end
  NilProxy = klass.new
  def try
    NilProxy
  end
end

# define #tap
class Object
  def tap(&block)
    block.call(self)
    self
  end
end
