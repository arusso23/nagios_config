module Nagios
  
  # Usage:
  #   conf = Nagios::ConfigBuilder.new
  #   
  #   conf.foo = "bar"
  #   conf.define("test") do |test|
  #     test.a = "b"
  #     test.a.comment("foo")
  #   end
  #   
  #   puts conf
  class ConfigBuilder
    attr_accessor :root
    
    def initialize(root=Nagios::Config.new)
      self.root = root
    end
    
    def [](name)
      var = get_variable_named(name)
      if var
        extend(var.val.value, var)
      end
    end
    
    def []=(name, value)
      set_variable_named(name, value)
      value
    end
    
    def define(type)
      raise "can't define in a define" if root.is_a?(Nagios::Define)
      define = Nagios::Define.new
      define.add_node(Nagios::Type.new(type.to_s))
      root.add_node(define)
      yield self.class.new(define)
      define
    end
    
    def break
      root.add_node(Nagios::Whitespace.new("\n"))
    end
    
    def comment(string)
      root.add_node(Nagios::Comment.new(string))
    end
    
    def to_s
      Nagios::Formater.new.format(root)
    end
    
    def method_missing(name, *args)
      if name.to_s =~ /=$/ && args.length == 1
        self[name.to_s.chomp("=")] = args.first
      elsif args.empty?
        self[name]
      else
        super
      end
    end
    
    private
    def get_variable_named(name)
      root.nodes.find do |node|
        node.is_a?(Nagios::Variable) && node.name.value == name.to_s
      end
    end
    
    def set_variable_named(name, value)
      var = get_variable_named(name)
      if var && value.nil?
        root.remove_node(var)
      elsif var && value.is_a?(Nagios::Variable)
        var.val = value.val
      elsif var && value == true
        var.val.value = "1"
      elsif var && value == false
        var.val.value = "0"
      elsif var
        var.val.value = value.to_s
      else
        var = Nagios::Variable.new
        var.add_node(Nagios::Name.new(name))
        var.add_node(Nagios::Value.new(value))
        root.add_node(var)
      end
      var
    end
    
    def extend(value, parent)
      metaclass = class << value; self; end
      metaclass.send(:define_method, :comment) do |string|
        parent.add_node(Nagios::TrailingComment.new(string))
      end
      value
    end
    
    
  end
end