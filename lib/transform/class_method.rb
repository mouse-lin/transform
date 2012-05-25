# -*- encoding : utf-8 -*-
module Transform 

  #初步include时候提供的ClassMethods方法，用于生成table_name
  module ClassMethods
    attr_accessor :attributes, :table_name, :indexs, :index_array  #字段获取数据格式
    def attributes 
      @attributes ||= { }
    end
 
    def  indexs
      @indexs ||= []
    end
 
    #初始化添加字段项
    def attribute(name, type = nil,  options = { } )
      attributes[name] = Attribute.new(self,name,type,options) unless DataStore.default_key.include? name
    end
 
    def index_array
      @index_array ||=[] 
    end
 
    #建立索引
    def indexes (name)
      indexs << Index.new(name, self)
      index_array << name
    end
 
 
    #调用此方法类的name 
    def table_name
      #pluralize 用到active_support方法
      @table_name ||= name.pluralize.underscore
    end
 
    #--------------------- 数据库操作方法(全类方法) ------------------------- 
    #TODO 以下搜索出来的结果均不为对象，为json格式
 
    #默认获取所有记录
    # TODO  数据格式: contents里面格式 => "string" 模式切换为symbol
    def all
      results = []
      TableCreator.db[self.table_name.to_sym].all.each do |d|
        results <<  transolate_values(d)
      end
      return results
    end
 
    #TODO 是否需要新的进程去删除index数据
    #删除所有数据
    def delete_all
      Transform.db.run("delete from #{ table_name  }")
      indexs.each do |i|
        Transform.db.run("delete from #{ i.table_name  }")
      end
    end
    
    #TODO 是否需要新的进程去删除index数据
    #单个删除函数
    def delete id
      Transform.db.from(table_name).filter('id=?',id).delete
      indexs.each do |i|
        Transform.db.from(i.table_name).filter('id=?',id).delete
      end
    end
 
 
    #find搜索方式 => 搜索的字段必须有index
    def find options={  }
      process_num = Transform.process_num
      #结果存放在memcache中
      $cache = Memcached.new("localhost:11211")
      process_num.times do
        $cache.set "#{ process_num }_results",[]
      end
      process_num.times do |p|
        Process.fork{ 
          index_array = []
          result_array = []
          options.each do |k,v|
            #--------------- 时间测试 -------------------------------
            puts "\033[1;32m--- #{ p+1 } Pro开始搜索 ---\033[0m"
            query_start_time = Time.now()
            #----------------------------------------------
            databaseset = Transform.db.from("index_" + self.table_name +  "_on_" + k.to_s)
            part_num = databaseset.count/process_num
            unless p ==  (process_num - 1)
              search_quantity = part_num
            else
              search_quantity = databaseset.count - (process_num - 1) * part_num
            end
            #搜索条件并且join index table
            unless p == 0
              index_array = databaseset.limit(part_num*p+1,search_quantity).filter('name=?',v).join(self.table_name,:id => :id)
            else
              index_array = databaseset.limit(search_quantity).filter('name=?',v).join(self.table_name,:id => :id)
            end
            #----------------------------------------------
            puts "\033[1;32m #{ p+1 } Pro 搜索结束,所花的时间为: \033[1;31m#{ Time.now() - query_start_time }s\033[0m "
            #p "--- 开始整理数据 ---"
            #----------------------------------------------
            result_start_time = Time.now()
 
            index_array.each do |r|
              result_array << transolate_values(Transform.db.from(self.table_name).filter('id=?',r[:id]).first)
            end
            #----------------------------------------------
            #p "---  最终结果整理结束(所花的时间为:#{ Time.now() - result_start_time }s) ---"
            #----------------------------------------------
 
          end
          $cache.set "#{ p+1 }_results", result_array
          #$cache.set "#{ p+1 }_results", index_array
        }
      end
      Process.waitall
      results = []
      process_num.times do |p|
        process_hash_name = "#{ p + 1 }_results"
        results += $cache.get(process_hash_name)
        $cache.set(process_hash_name,[])
      end
      return results
    end
    #----------------------------------------------
 
    #第一条记录 
    def first
      data = Transform.db.from(table_name).first
      transolate_values data
    end
 
    #保存大量数据
    def multi_save datas
      process_num = Transform.process_num
      number = datas.count
      #根据配置进程参数生成进程数处理
      group_num = number/process_num
 
      process_num.times do |t|
        t += 1
        start_index = t == 1? 0 : ((t-1)*group_num)
        end_index = t == process_num ? (number - 1) : (t*group_num - 1)
        #p "t 是#{ t } | start_index: #{ start_index } | end_index: #{ end_index }"
        #p datas[start_index..end_index].count
        #进程数量
        pro = Process.fork{  
          #thread_first_startTime = Time.now()
          datas[start_index..end_index].each do |d|
            d.save
          end
          thread_first_endTime = Time.now()
          #p " ** Thread#{ t } cost time: #{ thread_first_endTime - thread_first_startTime }s **"
        }  
      end
      Process.waitall
    end
 
    #解释获取records
    def transolate_values d
      unless d.nil?
        content_hash = Rufus::Json.decode(d[:contents])
        d.delete(:added_id)
        d.delete(:contents)
        content_hash.merge! d
        # 测试使用代码
        puts " \033[1;35m******  search  result : ******\033[0m\n \033[22;32m#{ content_hash }\033[0m"
        # 测试使用代码
      end
      return content_hash 
    end
  end

end
