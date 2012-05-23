require 'uuidtools'
#类型UUID
#----------------------------------------------
module Transform
  class UUID
    class << self
      def generate_uuid 
        UUIDTools::UUID.timestamp_create.to_s
      end
    end
  end
end
