module Transform
  #对象方法 - save |
  module ObjectMethods
    attr_accessor :contents #实际获取需要创建的数据
 
    def save
      #采用连接数据库后获取UUID, 但是效率低，不采用
      #uuid = TableCreator.db["select UUID()"].first[:"UUID()"]
      uuid = UUID.generate_uuid
      save_index_data uuid
      contents = set_data_value
      data_hash = { 
        :id => uuid, 
        :created_at => Time.now(),
        :updated_at => Time.now(),
        :contents => contents
     }
     puts "\033[22;32m #{ data_hash } \033[0m"
     TableCreator.db[self.class.table_name.to_sym].insert(data_hash)
   end
 
    #初始化函数
    def initialize(opt={  })
      @contents = opt
    end
 
    private
    #赋值保存
    def set_data_value
      @contents.each do |k,v|
        self.class.attributes[k] = v if self.class.attributes[k]
      end
      Rufus::Json.encode(self.class.attributes)
    end

    #保存index数据
    def save_index_data uuid
      contents.each do |k,v|
        if (self.class.index_array.include? k)
          index_table_name = "index_" + self.class.table_name +  "_on_" + k.to_s 
          index_data_hash = { :id => uuid, :name => v }
          Transform.db.from(index_table_name).insert(index_data_hash)
        end
      end
    end

  end

end
