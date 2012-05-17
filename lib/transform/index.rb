# index table
#---------------------------------
# primary_key :id
# string :name

module Transform
  class Index
    attr_accessor :name, :klass, :table_name
    def initialize name, klass
      @name = name
      @klass = klass
    end

    #索引表名
    def table_name
      "index_" + self.klass.table_name +  "_on_" + self.name.to_s 
    end

  end
end
