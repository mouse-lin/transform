# -*- encoding : utf-8 -*-
require "rubygems"
require 'sequel'
DB = Sequel.connect( :adapter  => "mysql",  
                :host     => "localhost",  
                :user     => "root",  
                :password => "000",  
                :database => "gp_development"  )
require "active_record"
require "factory_girl"
ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :host => "localhost",
  :username => "root",
  :password => "000",
  :database => "gp_development"
)


class User < ActiveRecord::Base
  self.table_name =  "items"

  class << self

    #建立测试数据
    def generate_test_datas number = 100
      p "#-------------------- 开始模拟并发插入#{ number }条数据( 关系型存储方式 )--------------------------"
      datas = FactoryGirl.build_list(:user,number)
      startTime = Time.now()
      time = 1
      datas.each do |d|
        time += 1
        p "#-------------------- 已经保存 #{ number/2 }条数据,此时花费时间为：#{ Time.now() - startTime }s ----------------------------" if time == (number/2)
        d.save
      end

      #结束时间
      endTime = Time.now()
      p " **  所花费时间为 : #{ endTime - startTime }s **"
    end

  end

end

#--------------------test code--------------------------
FactoryGirl.define do
  #sequence(:string) {|n| "There are #{ n } test data" }
  sequence(:string) {|n| "cats" }
  factory :user do
    name {  generate(:string) }
    remark {  generate(:string) }
    address {  generate(:string) }
    phone {  generate(:string) }
    age {  20 }
    number {  generate(:string) }
    created_at { Time.now }
    updated_at { Time.now }
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
  when "search"
  #----------------------------------------------  搜索测试
  #开始时间
    p "#----------------- 开始模拟搜索 50000条记录 (关系型模式) -----------------------------"
    startTime = Time.now()
    p User.where(:name => "cats").count
    p "#-----------------搜索结束  所花费时间为：#{ Time.now() - startTime  }s-----------------------------"
  when "DDL"
    #-------------------- 插入索引表测试 DDL阻塞 --------------------------
    # 删除索引DB.run("drop index index_items_on_name on items)"; 查看索引 show index from items
    p "#----------------- 开始模拟DDL阻塞 50000条记录 (关系型模式) -----------------------------"
    start_time = Time.now()
    DB.run(" alter table items add index index_items_on_name (name) ; ")
    #----------------------------------------------
    User.generate_test_datas 1 
    p "#-----------------  模拟DDL阻塞删除1条数据结束, 所花费时间为：#{ Time.now() - start_time }s -----------------------------"
  when "exit"
    break
  end
end
