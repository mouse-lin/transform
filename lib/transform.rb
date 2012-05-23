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
require "./transform/lib/transform/attribute"
require "./transform/lib/transform/class_method"
require "./transform/lib/transform/object_method"
require "./transform/lib/transform/index"
require "./transform/lib/transform/type/uuid"
require 'rufus-json'
require 'memcached'
require 'json'
module Transform

  class << self
    attr_accessor :datastore, :db, :cache, :process_num

    #初始化配置数据库
    def configure config
      if config[:process_num]
        @process_num = config[:process_num]
        config.delete(:process_num)
      end
      self.db = Sequel.connect(config)
      #获取数据库，用于后面创建表
      TableCreator.db = db
      DataStore.default_key = [:id,:created_at,:updated_at]
    end

    def process_num
      @process_num ||= 2
    end

    #创建数据库表
    def create_table!
      TableCreator.create_table!
    end

    #删除数据库表操作
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
          #类方法
          extend ClassMethods
          #对象方法 include
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
  end

end
