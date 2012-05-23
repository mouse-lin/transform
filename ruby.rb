# -*- encoding : utf-8 -*-
require "rubygems"
#require "json"
#require 'rufus-json'
require "factory_girl"
require 'memcached'
require "./transform/lib/transform"
Transform.configure :adapter  => "mysql",  
                   :host     => "localhost",  
                   :user     => "root",  
                   :password => "000",  
                   :database => "gp_development"  
                   :process_num => 2
class  User 
  include Transform::Document
  attribute :name, String #, { :default => "mouse" }
  attribute :number, String #, { :default => "mouse" }
  attribute :address, String
  attribute :phone, String
  attribute :remark, String
  attribute :age, Integer
  
  indexes :name
  

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
    def generate_test_datas number = 100
      datas = FactoryGirl.build_list(:user,number)
      p "#-------------------- 开始模拟并发插入#{ number }条数据(  无模式扩展存储方式  进程数 #{ Transform.process_num } )--------------------------"
      startTime = Time.now()
      self.multi_save datas
      #结束时间
      endTime = Time.now()
      p " **  所花费时间为 : #{ endTime - startTime }s **"
    end

  end

end
#---------------------test code-------------------------
#thread_f  = Thread.new{ User.generate_test_datas 100,"Apple"}
#User.generate_test_datas 1000,"Apple"
#User.generate_test_datas 10000,"Apple"

#----------------------------------------------  构建测试数据
FactoryGirl.define do
  #sequence(:string) {|n| "There are #{ n } test data" }
  #sequence(:string) {|n| "There are test data" }
  sequence(:string) {|n| "Mouse" }
  factory :user do
    name {  generate(:string) }
    number {  "mouse" }
    remark {  "mouse" }
    phone {  "mouse" }
    age {  20 }
    address {  "mouse" }
  end
end

while true do
  print "input command:"
  command = gets.chomp
  case command
  #----------------------------------------------  并发插入数据测试
  #TODO  索引删除与计时,自动执行下一条程序
  when "i100"
    User.generate_test_datas 100
  when "i1000"
    User.generate_test_datas 1000
  when "i10000"
    User.generate_test_datas 10000
  when "search"
  #----------------------------------------------  搜索测试
  #开始时间
    #startTime = Time.now()
    p "#-----------------开始模拟搜索1000000条数据记录(无模式扩展存储方式) 进程数 #{ Transform.process_num }-----------------------------"
    p User.find(:name => "Apple").count
    #p "#-----------------搜索结束  所花费时间为：#{ Time.now() - startTime  }s-----------------------------"
  when "create_table"
    #---------------------------------------------- 创建数据库表
    Transform.create_table!
  when "exit"
    break
  end
end
