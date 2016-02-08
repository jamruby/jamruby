require "org/jamruby/ext/NativeArray"
require "org/jamruby/ext/Bytes"

module JamRuby
  class NativeArray
    include Enumerable
    def [] i
      get(i)
    end
    
    def []= i,v
      set i,v
    end
    
    def length
      array.length
    end
    
    def each &b
      for i in 0..array.length-1
        b.call get(i)
      end
    end
    
    def get i
      if array.isArrayOfByte
        array.getByte i
      elsif array.isArrayOfChar
        array.getChar i
      elsif array.isArrayOfDouble
        array.getDouble i
      elsif array.isArrayOfFloat
        array.getFloat i
      elsif array.isArrayOfLong
        array.getLong i
      elsif array.isArrayOfObject
        array.getObject i
      elsif array.isArrayOfShort
        array.getShort i
      end
    end
    
    def set i, v
      if array.isArrayOfByte
        array.setByte i, v
      elsif array.isArrayOfChar
        array.setChar i, v
      elsif array.isArrayOfDouble
        array.setDouble i, v
      elsif array.isArrayOfFloat
        array.setFloat i, v
      elsif array.isArrayOfLong
        array.setLong i, v
      elsif array.isArrayOfObject
        array.setObject i, v
      elsif array.isArrayOfShort
        array.setShort i, v
      end
    end    
    
    attr_reader :array
    def initialize nary
      @array = JAVA::Org::Jamruby::Ext::NativeArray.new(nary)
    end
    
    def native
      data
    end
    
    def data
      array.data
    end
    
    class << self
      alias :_new :new
    end
    
    def self.new nary
      ins = _new(nary)
      
      if ins.array.isArrayOfByte
        return ByteArray.new(nary)
      end
      
      return ins
    end
  end
  
  class ByteArray < NativeArray
    def writeToOutputStream os
      JAVA::Org::Jamruby::Ext::Bytes.writeToOutputStream data, os
    end
    
    def writeToPath pth
      JAVA::Org::Jamruby::Ext::Bytes.writeToPath data, pth
    end
    
    def encode64
      JAVA::Org::Jamruby::Ext::Bytes.encode64(data)
    end
    
    def self.new nary
      _new nary
    end
  end
end
