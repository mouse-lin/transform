# -*- encoding : utf-8 -*-
#require "transform"
#使用Rails提供的一些方法 -> active_support
#外部引用均为Transform调用方法
#----------------------------------------------
#require 'rails'
require 'active_support/inflector'
require 'active_support' #=> json
require "sequel"
require "./transform/lib/transform/table_creator"
require "./transform/lib/transform/data_store"
require "./transform/lib/transform/index"
require "./transform/lib/transform/type/uuid"
require 'rufus-json'
require 'memcached'
#require 'json'
module Transform

  class << self
    attr_accessor :datastore, :db, :cache
    #初始化配置数据库
    def configure config
      self.db = Sequel.connect(config)
      #获取数据库，用于后面创建表
      TableCreator.db = db
      DataStore.default_key = [:id,:created_at,:updated_at]
    end

    def create_table!
      TableCreator.create_table!
    end

    def drop_table! table_name
      TableCreator.drop_table! table_name
    end

  end

  module Document
    class << self
      attr_accessor :document
      #在别的方法中引入时候触发
      def included klass
        document << klass
        klass.class_eval do
          extend ClassMethods
          #对象方法 include
          #extend Attribute  
          include ObjectMethods   
          attribute :id, UUID #->  采取直接用sql保存的uuid
          attribute :created_at, Time
          attribute :updated_at, Time
        end
      end

      #初始化document
      def document
        @document ||= []
      end
    end

    #无模式存储数据的格式字段
    class Attribute
      attr_accessor :klass, :name, :type, :default_value
      #def attribute(name, type = nil, options = {})
      #  #@atrtibute = "mouse"
      #  #puts type 
      #  @values = { :value => name, :type => type }
      #  #attributes[name] = Attribute.new(self, name, type, options)
      #end

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

    #对象方法 - save |
    module ObjectMethods
      attr_accessor :contents #实际获取需要创建的数据
      def save

        uuid = TableCreator.db["select UUID()"].first[:"UUID()"]

        contents.each do |k,v|
          index_table_name = "index_" + self.class.table_name +  "_on_" + k.to_s 
          index_data_hash = { :id => uuid, :name => v }
          Transform.db.from(index_table_name).insert(index_data_hash)
        end

        contents = set_data_value
        data_hash = { 
          :id => uuid, 
          :created_at => Time.now(),
          :updated_at => Time.now(),
          :contents => contents
       }
       TableCreator.db[self.class.table_name.to_sym].insert(data_hash)
      end

      #初始化函数
      def initialize(opt={  })
        @contents = opt
       # dataset =  TableCreator.db.from(self.class.table_name)
       # uuid = TableCreator.db["select UUID()"].first[:"UUID()"]
       # dataset.insert({ :created_at => Time.now(), :id => uuid })
       # #puts @records
      end


      private
      
      #赋值保存
      def set_data_value
        @contents.each do |k,v|
          self.class.attributes[k] = v if self.class.attributes[k]
        end
        Rufus::Json.encode(self.class.attributes)
      end

    end

    #初步include时候提供的ClassMethods方法，用于生成table_name
    module ClassMethods

      attr_accessor :attributes, :table_name, :indexs  #字段获取数据格式
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

      #建立索引
      def indexes (name)
        indexs << Index.new(name, self)
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

        #结果存放在memcache中
        $cache = Memcached.new("localhost:11211")
        $cache.set "results_pro_f",[]
        $cache.set "results_pro_s",[]

        #第一个搜索的进程
        Process.fork{ 
          index_array = []
          result_array = []
          options.each do |k,v|
            #--------------- 时间测试 -------------------------------
            p "--- 开始搜索 ---"
            query_start_time = Time.now()
            #----------------------------------------------

            databaseset = Transform.db.from("index_" + self.table_name +  "_on_" + k.to_s)


            all_count = databaseset.count/2
            index_array = databaseset.limit(all_count).filter('name=?',v).join(self.table_name,:id => :id)

            #----------------------------------------------
            p "--- 搜索结束(所花的时间为: #{ Time.now() - query_start_time }s) ---"
            p "--- 开始整理数据 ---"
            #----------------------------------------------
            result_start_time = Time.now()

            index_array.each do |r|
              result_array << transolate_values(Transform.db.from(self.table_name).filter('id=?',r[:id]).first)
            end
            #----------------------------------------------
            p "---  最终结果整理结束(所花的时间为:#{ Time.now() - result_start_time }s) ---"
            #----------------------------------------------

          end
          $cache.set "results_pro_f", result_array
        }

        #第二个搜索进程
        Process.fork{ 
          index_array = []
          result_array = []
          options.each do |k,v|
            #--------------- 时间测试 -------------------------------
            p "--- 开始搜索 ---"
            query_start_time = Time.now()
            #----------------------------------------------

            databaseset = Transform.db.from("index_" + self.table_name +  "_on_" + k.to_s)


            all_count = databaseset.count
            index_array = databaseset.limit(all_count/2,all_count - all_count/2).filter('name=?',v).join(self.table_name,:id => :id)

            #----------------------------------------------
            p "--- 搜索结束(所花的时间为: #{ Time.now() - query_start_time }s) ---"
            p "--- 开始整理数据 ---"
            #----------------------------------------------
            result_start_time = Time.now()

            index_array.each do |r|
              result_array << transolate_values(Transform.db.from(self.table_name).filter('id=?',r[:id]).first)
            end
            #----------------------------------------------
            p "---  最终结果整理结束(所花的时间为:#{ Time.now() - result_start_time }s) ---"
            #----------------------------------------------

          end
          $cache.set "results_pro_s", result_array
        }

        Process.waitall
        $cache.get("results_pro_f") +  $cache.get("results_pro_s")
        #$cache.get "results_pro_f"
        #index_array
       # index_array = []
       # result_array = []
       # options.each do |k,v|
       #   index_array = Transform.db.from("index_" + self.table_name +  "_on_" + k.to_s).filter('name=?',v).join(self.table_name,:id => :id)
       # end
       # #index_array.each do |r|
       # #  result_array << transolate_values(Transform.db.from(self.table_name).filter('id=?',r[:id]).first)
       # #end
       # index_array
      end
      #----------------------------------------------

      #第一条记录 
      def first
        data = Transform.db.from(table_name).first
        transolate_values data
      end

      #解释获取records
      def transolate_values d
        unless d.nil?
          content_hash = Rufus::Json.decode(d[:contents])
          d.delete(:added_id)
          d.delete(:contents)
          content_hash.merge! d
        end
        return content_hash 
      end

    end
  end

end
