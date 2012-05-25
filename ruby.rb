# -*- encoding : utf-8 -*-
#memcached -p 11211 &
require "rubygems"
#require "friendly"
#require "json"
#require 'rufus-json'
require "factory_girl"
require 'memcached'

require "./transform/lib/transform"
Transform.configure :adapter  => "mysql",  
                   :host     => "localhost",  
                   :user     => "root",  
                   :password => "000",  
                   :database => "gp_development",
                   :process_num => 2
class Order
  include Transform::Document
  attribute :name, String
  attribute :number, String
  indexes :name
  class << self
    #指定生成测试数据
    def generate_test_datas number = 100, opt = {  }
      if opt.empty?
        datas = FactoryGirl.build_list(:order,number)
        p "#-------------------- 开始模拟并发插入#{ number }条数据(  无模式扩展存储方式  进程数 #{ Transform.process_num } )--------------------------"
        startTime = Time.now()
        self.multi_save datas
        #结束时间
        endTime = Time.now()
        p " **  所花费时间为 : #{ endTime - startTime }s **"
      else
        p "nothings"
      end
    end
  end
end

class Test
  include Transform::Document
  attribute :name, String
  attribute :number, String
  indexes :name
  class << self
    #指定生成测试数据
    def generate_test_datas number = 100, opt = {  }
      if opt.empty?
        datas = FactoryGirl.build_list(:order,number)
        p "#-------------------- 开始模拟并发插入#{ number }条数据(  无模式扩展存储方式  进程数 #{ Transform.process_num } )--------------------------"
        startTime = Time.now()
        self.multi_save datas
        #结束时间
        endTime = Time.now()
        p " **  所花费时间为 : #{ endTime - startTime }s **"
      else
        p "nothings"
      end
    end
  end
end

class  User 
  include Transform::Document
  attribute :name, String #, { :default => "mouse" }
  attribute :number, String #, { :default => "mouse" }
  attribute :address, String
  attribute :phone, String
  attribute :remark, String
  attribute :age, Integer
  
  indexes :name
  #indexes :number

  #类方法
  class << self

    #删除数据库apples表所有数据
    def delete_all_record 
      #删除表数据
      Friendly.db.run("delete from #{ table_name }")
      #删除index表
      Friendly.db.run("delete from index_#{ table_name }_on_name")
      p "delete #{ table_name }'s datas success! " 
    end

    #指定生成测试数据
    def generate_test_datas number = 100, opt = {  }
      if opt.empty?
        datas = FactoryGirl.build_list(:user,number)
        puts "\033[1;32m开始模拟并发插入\033[1;31m#{ number }\033[0m\033[1;32m条数据( 无模式扩展存储方式  进程数#{ Transform.process_num } )\033[0m\n"
        startTime = Time.now()
        self.multi_save datas
        #结束时间
        endTime = Time.now()
        puts "\033[1;32m ****** #{ number }条数据所花费时间为: ****** \033[0m \033[1;31m#{ endTime - startTime }s \033[0m\n"
      else
        p "nothing"
      end
    end

  end

end
#---------------------test code-------------------------
#thread_f  = Thread.new{ User.generate_test_datas 100,"Apple"}
#User.generate_test_datas 1000,"Apple"
#User.generate_test_datas 10000,"Apple"

#----------------------------------------------  构建测试数据
FactoryGirl.define do
  sequence(:string) {|n| "result" }
  factory :user do
    name {  generate(:string) }
    number {  "mouse" }
    remark {  "mouse" }
    phone {  "mouse" }
    age {  20 }
    address {  "mouse" }
  end
  factory :order do
    name {  "test_order" }
    number {  "mouse" }
  end
end

while true do

  print "input command:"
  command = gets.chomp
  case command
  #----------------------------------------------  并发插入数据测试
  #TODO  索引删除与计时,自动执行下一条程序
  when "first"
    p User.first
  when "find"
    p "#----------------- 模拟从分布式集群数据库中搜索数据 -----------------------------"
    p User.find(:name => "result").count
  when "delete_all"
    User.delete_all
    p "删除成功"
  when "i1"
    User.generate_test_datas 100
  when "i2"
    User.generate_test_datas 1000
  when "i3"
    User.generate_test_datas 10000
  when "i4"
    Transform.process_num = 5
    User.generate_test_datas 100000
  when "search"
  #----------------------------------------------  搜索测试
  #开始时间
    startTime = Time.now()
    puts "\033[1;32m开始模拟搜索\033[1;31m1000000\033[1;32m条数据记录(无模式扩展存储方式) 进程数 #{ Transform.process_num }\033[0m"
    p Order.find(:name => "result").count
    #puts "\033[22;32m ****** 搜索结束  所花费时间为：****** \033[1;31m#{ Time.now() - startTime  }s\033[0m"
  when "DDL"
    #---------------------------------------------- 创建数据库表
    puts "\033[1;32m开始模拟避免DDL阻塞测试\033[0m"
    puts "#-------------------\033[1;31mTable Creating\033[0m---------------------------#"
    startTime = Time.now()
    Transform.create_table!
    test = Test.new(:name => "test", :number => "110")
    start_ddl_time = Time.now()
    test.save
    puts "#----------------------------------------------#"
    puts "\033[1;32m创建数据结束  所花费时间为：\033[1;31m#{ Time.now() - start_ddl_time  }s\033[0m"
    puts "\033[1;32m模拟避免DDL阻塞结束  所花费时间为：\033[1;31m#{ Time.now() - startTime  }s\033[0m"
 # when "p1"
 #   config = { :adapter  => "mysql",  
 #                  :host     => "localhost",  
 #                  :user     => "root",  
 #                  :password => "000",  
 #                  :database => "gp_development",
 #                  :process_num => 1
 #   }
 #   User.generate_test_datas 100,config
  when "exit"
    break
  when "create_table"
    Transform.create_table!
  when "create_order_datas"
    Order.generate_test_datas 100000
  end

end
