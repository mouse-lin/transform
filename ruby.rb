# -*- encoding : utf-8 -*-
#db.execute("create table stockTable(name varchar(20),count int);")
#require "mysql"
#make mysql to nosql
#json
#make to data to json object 
#gem "active_record", '2.3.5'
#require "active_record"

#ActiveRecord::Base.establish_connection(
#  :adapter => "mysql",
#  :host => "localhost",
#  :username => "root",
#  :password => "000",
#  :database => "gp_development"
#)
#----------------------------------------------
# friendly
#require "friendly"

require "rubygems"
#require "json"
#require 'rufus-json'
require "factory_girl"

require "./transform/lib/transform"
Transform.configure :adapter  => "mysql",  
                   :host     => "localhost",  
                   :user     => "root",  
                   :password => "000",  
                   :database => "gp_development"  

#Rufus::Json.backend = :json
#Friendly.configure :adapter  => "mysql",  
#                   :host     => "localhost",  
#                   :user     => "root",  
#                   :password => "000",  
#                   :database => "gp_development"  
#
#include Friendly::Document
#indexes :number
class  User 
  include Transform::Document
  attribute :name, String #, { :default => "mouse" }
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
    def generate_test_datas number = 100, string, process_num
      FactoryGirl.define do
        #sequence(:string) {|n| "There are #{ n } test data" }
        #sequence(:string) {|n| "There are test data" }
        sequence(:string) {|n| string }
        factory :user do
          name {  generate(:string) }
        end
      end

      datas = FactoryGirl.build_list(:user,number)
      group_num = number/process_num
      process_num.times do |t|
        t += 1
        start_index = t == 1? 0 : ((t-1)*group_num)
        end_index = t == process_num ? (number - 1) : (t*group_num - 1)
        #p "t 是#{ t } | start_index: #{ start_index } | end_index: #{ end_index }"
        #p datas[start_index..end_index].count
        #进程数量
        pro = Process.fork{  
          thread_first_startTime = Time.now()
          datas[start_index..end_index].each do |d|
            d.save
          end
          thread_first_endTime = Time.now()
          p " ** Thread#{ t } cost time: #{ thread_first_endTime - thread_first_startTime }s **"
        }  
      end

   #   all_startTime = Time.now()
   #   p1 = Process.fork{  
   #     thread_first_startTime = Time.now()
   #     datas[0..(datas.length/2 - 1)].each do |d|
   #       d.save
   #     end
   #     thread_first_endTime = Time.now()
   #     p " ** Thread 1 cost time: #{ thread_first_endTime - thread_first_startTime }s **"
   #   }  
   #   
   #  # thread_first = Thread.new{ 
   #  #   thread_first_startTime = Time.now()
   #  #   datas[0..(datas.length/2 - 1)].each do |d|
   #  #     d.save
   #  #   end
   #  #   thread_first_endTime = Time.now()
   #  #   p " ** Thread 1 cost time: #{ thread_first_endTime - thread_first_startTime }s **"
   #  # }

   #   p2 =  Process.fork{ 
   #     startTime = Time.now()
   #     datas[datas.length/2..(datas.length-1)].each do |d|
   #       d.save
   #     end
   #     endTime = Time.now()
   #     p " ** Thread 2 cost time: #{ endTime - startTime }s **"
   #   }

       Process.waitall
   #   all_endTime = Time.now()
   #   p " ** Thread 3 cost time: #{ all_endTime - all_startTime }s **"

     # thread_first.join
      #thread_second.join(5)
     # datas.each do |d|
     #   d.save
     # end

    end

  end

end
#----------------------------------------------
#factory_girl

#---------------------test code-------------------------

#$mouse = [1,23]
#fork do 
#  p $mouse[0] = 2
#end
#sleep 1
#p pid = Process.wait
#p $mouse[0]

#:number = [12721,112]
#p1 = Process.fork{  
#  sleep 1
#  p :number[1] = "mouse"
#  p "p1 1 seconds #{Process.pid};"  
#}  
#Process.waitpid(p1)
#p :number[1]
#p "主进程退出"
#p2 = Process.fork{  
#  sleep 1
#  p @@number[1]
#  p "p2 2 seconds #{Process.pid};"  
#}
# p @@number 

#Friendly.create_tables!
#开始时间
startTime = Time.now()

#thread_first = Thread.new{ 
#  startTime = Time.now()
#  User.generate_test_datas 5000  
#  p "thread 1"
#  endTime = Time.now()
#  p " ** cost time: #{ endTime - startTime }s **"
#
#}
#thread_second = Thread.new{ 
#  startTime = Time.now()
#  User.generate_test_datas 5000  
#  p "thread 2"
#  endTime = Time.now()
#  p " ** cost time: #{ endTime - startTime }s **"
#}
#thread_first.join
#thread_second.join


#a = User.new(:name => "There are test data")
#a.save
#User.delete User.first[:id]
#User.first#a = User.new(:name => "mouse")
#a.save
#User.delete_all

#Transform.create_table!
#a = User.find(:name => "search data")
#a = User.find(:name => "mouse")   #16.844959906s
#p a.count

#TODO  索引删除与计时
User.generate_test_datas 100000,"Trahder mouse" ,5

#User.delete_all_record  #分装进去
# TransForm: 10000 6-7s  100000 28s 1000000 600s || Friendly:  100000条记录 176.260620606s | 10000条记录 25.986018094s
#User.generate_test_datas 10000  
#user_datas = User.all(:name => "There are test data") #37.843820667s -->  太慢了
#p user_datas.count

#结束时间
endTime = Time.now()

p " ** cost time: #{ endTime - startTime }s **"
#count = Apple.all(:number => "mouse")
#p count

#生成测试数据
#user = FactoryGirl.build_list(:apple,100)
#user = FactoryGirl.build(:apple)
#user.save
#user.each do |u|
#  u.save
#end

#查询效率
#----------------------------------------------




#class   User
#  include Friendly::Document
# # include Friendly::Document
# # attribute :name, String
# # attribute :address, String
# # attribute :phone, String
# # indexes :name
#  #set_table_name "users"
#end
#@user = User.new :name => "mouse"
#@user.save
#@test = Test.new :name => "mouse"
###@test = Test.new :name => "cat", :id => 5 
#@test.save
#@test = Test.all(:name => "mouse")
#puts @test.first.name
#puts User.all(:name => "mouse" ).first.id
#puts @test.count
#@test.each do|n|
#  puts n.name
#end



#class User < ActiveRecord::Base

#mouse = Apple.find("96773802-98af-11")
#mouse  = Apple.all(:name => "apple")
#mouse.first.destroy
#b = Apple.new(:name => "cat")
#b.save
