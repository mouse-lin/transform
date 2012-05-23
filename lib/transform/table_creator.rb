#table schema
#---------------------------------------------
# primary_key :added_id
# binary      :id,         :size => 16
# String      :contents, :text => true
# Time        :created_at
# Time        :updated_at

module Transform
  class TableCreator
  
    class << self
      attr_accessor :db 

      #调用数据库表创建器来创建需要的数据表
      def create_table!
        Document.document.each do |d|
          create_index d
          #创建数据库表
          unless db.table_exists?(d.table_name)
            db.create_table d.table_name do
              primary_key :added_id
              binary      :id,         :size => 16
              String      :contents, :text => true  #默认6W多个字符长度
              Time        :created_at
              Time        :updated_at
            end
            p "created #{ d.table_name } success!"
          else
            p "created error: #{ d.table_name } exists!"
          end
        end
      end

      #删除数据库表,需要传入相应删除数据库表的table_name
      def drop_table! table_name
        if db.table_exists?(table_name)
          Transform.db.run("drop table #{ table_name }") 
          puts "#{ table_name } delete success !"
        else
          puts "no #{ table_name } table exists !"
        end
      end

      #创建并且判断索引
      def create_index d
        unless d.indexs.empty?
          d.indexs.each do |i|
            index_table_name = "index_" + i.klass.table_name +  "_on_" + i.name.to_s 
            #TODO 使用多进程来创建
            #TODO 创建索引之后，利用新进程去搜索该表是否有存在的结果，有的话，立即保存
            unless db.table_exists?(index_table_name) 
              db.create_table index_table_name do
                primary_key :added_id
                binary      :id,         :size => 16
                String :name
              end
              p "created #{ index_table_name  } success!"
            else
              p "#{ index_table_name} exists!"
            end
          end
        end
      end

    end

  end
end
