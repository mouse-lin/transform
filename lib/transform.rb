#require "transform"
#使用Rails提供的一些方法
require 'active_support/inflector'
require "sequel"
require "./transform/lib/transform/table_creator"
module Transform

  class << self
    attr_accessor :datastore, :db, :cache
    #初始化配置数据库
    def configure config
      self.db = Sequel.connect(config)
      #获取数据库，用于后面创建表
      TableCreator.db = db
    end
    def create_table!
      TableCreator.create_table!
    end
    def drop_table!
      TableCreator.drop_table!
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
         # attribute :id,         UUID
         # attribute :created_at, Time
         # attribute :updated_at, Time
        end
      end
      #初始化document
      def document
        @document ||= []
      end
    end
    #初步include时候提供的ClassMethods方法，用于生成table_name
    module ClassMethods
      attr_writer :table_name
      #调用此方法类的name 
      def table_name
        @table_name ||= name.pluralize.underscore
      end
    end
  end

end
