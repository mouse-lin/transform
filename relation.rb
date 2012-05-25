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


class Apple < ActiveRecord::Base
  class << self

    #建立测试数据
    def generate_test_datas number = 100
      puts "\033[1;32m ****** 开始模拟并发插入#{ number }条数据( 关系型存储方式 ) ****** \033[0m"
      datas = FactoryGirl.build_list(:apple,number)
      startTime = Time.now()
      time = 1
      datas.each do |d|
        time += 1
        p "#-------------------- 已经保存 #{ number/2 }条数据,此时花费时间为：#{ Time.now() - startTime }s ----------------------------" if time == (number/2)
        d.save
        p d
      end
      #结束时间
      endTime = Time.now()
      puts "\033[1;32m ******  插入#{ number }条数据，所花费时间为 ****** :\033[1;31m #{ endTime - startTime }s \033[0m "
    end

  end
  
end

class User < ActiveRecord::Base
  self.table_name =  "items"

  class << self

    #建立测试数据
    def generate_test_datas number = 100
      puts "\033[1;32m ****** 开始模拟并发插入#{ number }条数据( 关系型存储方式 ) ****** \033[0m"
      datas = FactoryGirl.build_list(:user,number)
      startTime = Time.now()
      time = 1
      datas.each do |d|
        time += 1
        p "#-------------------- 已经保存 #{ number/2 }条数据,此时花费时间为：#{ Time.now() - startTime }s ----------------------------" if time == (number/2)
        d.save
        p d
      end
      #结束时间
      endTime = Time.now()
      puts "\033[1;32m ******  插入#{ number }条数据，所花费时间为 ****** :\033[1;31m #{ endTime - startTime }s \033[0m "
    end

  end

end

#--------------------test code--------------------------
FactoryGirl.define do
  #sequence(:string) {|n| "There are #{ n } test data" }
  sequence(:string) {|n| "test" }
  factory :apple do
    name {  "result" }
    number {  generate(:string) }
  end
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
  when "i1"
    User.generate_test_datas 100
  when "i2"
    User.generate_test_datas 500
  when "i3"
    Apple.generate_test_datas 10
  when "search"
  #----------------------------------------------  搜索测试
  #开始时间
    puts "\033[1;32m ****** 开始模拟搜索 10000条记录 (关系型模式) ****** \033[0m"
    startTime = Time.now()
    result = Apple.where(:name => "result")
    puts "\033[1;32m ****** 10000条件记录搜索结束 ，所花费时间为：\033[1;31m#{ Time.now() - startTime  }s\033[0m"
    result.each do |r|
      p r
    end
  when "DDL"
    #-------------------- 插入索引表测试 DDL阻塞 --------------------------
    # 删除索引DB.run("drop index index_items_on_name on items)"; 查看索引 show index from items
    puts "\033[1;32m ****** 开始模拟DDL阻塞 60000多条记录 (关系型模式) ****** \033[0m "
    start_time = Time.now()
    #DB.run(" alter table items add index index_items_on_name (name) ; ")
    DB.run("drop index index_items_on_name on items")
    #----------------------------------------------
    User.generate_test_datas 1 
    puts "\033[1;32m  ****** 模拟DDL阻塞插入1条数据结束, 所花费时间为：\033[1;31m#{ Time.now() - start_time }s\033[0m "
  when "exit"
    break
  end
end
