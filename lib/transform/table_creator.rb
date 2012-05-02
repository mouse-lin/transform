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

      #TODO:判断为index时候需要创建索引
      #调用数据库表创建器来创建需要的数据表
      def create_table!
        Document.document.each do |d|
          unless db.table_exists?(d.table_name)
            db.create_table d.table_name do
              primary_key :added_id
              binary      :id,         :size => 16
              String      :contents, :text => true
              Time        :created_at
              Time        :updated_at
            end
            puts "created #{ d.table_name } success!"
          else
            puts "created error: #{ d.table_name } exists!"
          end
        end
      end

      #删除数据库表
      def drop_table!
        Transform.db.run("drop table #{ :items }") 
      end

    end

  end
end
