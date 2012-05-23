module Transform
  #无模式存储数据的格式字段
  class Attribute
    attr_accessor :klass, :name, :type, :default_value
    def initialize klass, name, type, options
      @klass         = klass
      @name          = name
      @type          = type
      @default_value = options[:default]
      add_function
    end
  
    private
    def add_function
      n = name
      klass.class_eval do
        attr_reader  n
        eval <<-__END__
          def #{n}=(value)
            contents[:#{n}] = value
          end
        __END__
      end
    end
  end
end
