package org.jamruby.ext

import java.util.ArrayList
import java.util.Arrays
import java.io.FileOutputStream
import java.io.OutputStream

import android.util.Base64

class Bytes
  def self.writeToPath(ba:Object, pth:String):boolean
    os = FileOutputStream.new(pth)
    os.write byte[].cast(ba)
    os.close
    return true
  rescue => e
    Util.p e.toString
    return false
  end 
  
  def self.writeToOutputStream(ba:Object, os:OutputStream):boolean
    os.write byte[].cast(ba)
    return true
  rescue => e
    Util.p e.toString
    return false
  end     
  
  def self.encode64(ba:Object, flags:int = Base64.NO_WRAP):String
    Base64.encodeToString(byte[].cast(ba), flags)
  end
end

class NativeArray
  def self.isArray(o:Object):boolean
    o.getClass.isArray
  end

  def initialize ba:Object
    @array = ba
  end
  
  def data
    @array
  end
  
  def length():int
    if @array.getClass.isArray
      if byte[].class == @array.getClass
        return int(byte[].cast(@array).length)
      elsif char[].class == @array.getClass
        return int(char[].cast(@array).length)
      elsif short[].class == @array.getClass
        return int(short[].cast(@array).length)
      elsif long[].class == @array.getClass
        return int(long[].cast(@array).length)
      elsif float[].class == @array.getClass
        return int(float[].cast(@array).length)
      elsif double[].class == @array.getClass
        return int(double[].cast(@array).length)
      elsif Object[].class == @array.getClass
        return int(Object[].cast(@array).length)    
      else
        return -1
      end
    else
      return -1
    end
  end
  
  def getByte i:int
    int(byte[].cast(@array)[i]) & 0xff
  end
  
  def getInt i:int
    int[].cast(@array)[i]
  end  
  
  def getChar i:int
    char[].cast(@array)[i]
  end 
  
  def getShort i:int
    short[].cast(@array)[i]
  end
  
  def getLong i:int
    long[].cast(@array)[i]
  end
  
  def getFloat i:int
    float[].cast(@array)[i]
  end    
  
  def getDouble i:int
    double[].cast(@array)[i]
  end    
  
  def getObject i:int
    Object[].cast(@array)[i]
  end    

  def setByte i:int, b:byte
    byte[].cast(@array)[i] = b
  end
  
  def setInt i:int, v:int
    int[].cast(@array)[i] = v 
  end  
  
  def setChar i:int, c:char
    char[].cast(@array)[i] = c
  end 
  
  def setShort i:int, s:short
    short[].cast(@array)[i] = s
  end
  
  def setLong i:int, l:long
    long[].cast(@array)[i] = l
  end
  
  def setFloat i:int, f:float
    float[].cast(@array)[i] = f
  end    
  
  def setDouble i:int, d:double
    double[].cast(@array)[i] = d
  end    
  
  def setObject i:int, o:Object
    Object[].cast(@array)[i] = o
  end
  
  def toString():String
    if @array.getClass.isArray
      if byte[].class == @array.getClass
        return Arrays.toString(byte[].cast(@array))
      elsif char[].class == @array.getClass
        return Arrays.toString(char[].cast(@array))
      elsif short[].class == @array.getClass
        return Arrays.toString(short[].cast(@array))
      elsif long[].class == @array.getClass
        return Arrays.toString(long[].cast(@array))
      elsif float[].class == @array.getClass
        return Arrays.toString(float[].cast(@array))
      elsif double[].class == @array.getClass
        return Arrays.toString(double[].cast(@array))
      elsif Object[].class == @array.getClass
        return Arrays.toString(Object[].cast(@array))   
      else
        return nil
      end
    else
      return nil
    end
  end 
  
  def isArrayOfByte:boolean
    byte[].class == @array.getClass
  end
  
  def isArrayOfChar:boolean
    byte[].class == @array.getClass
  end 
  
  def isArrayOfShort:boolean
    short[].class == @array.getClass
  end 
  
  def isArrayOfLong:boolean
    long[].class == @array.getClass
  end 
  
  def isArrayOfDouble:boolean
    double[].class == @array.getClass
  end 
  
  def isArrayOfFloat:boolean
    float[].class == @array.getClass
  end 
 
  def isArrayOfObject:boolean
    Object[].class == @array.getClass
  end            
end

class ObjectList < ArrayList
  def self.create():ObjectList
    ol = ObjectList.new()
    ol.add Object.new
    ol.remove(0)
    ol
  end
  
  def addStr(str:String):void
    add str
  end
  
  def addInt(i:int):void
    add i
  end  
  
  def addFlt(i:float):void
    add i
  end 
  
  def addDbl(d:double):void
    add d
  end  
  
  def addObj(obj:Object):void
    add obj
  end
  
  def addBool(obj:boolean):void
    add obj
  end
  
  def setBool(idx:int, val:boolean):void
    set(idx, val)
  end  
  
  def setInt(idx:int, val:int):void
    set(idx, val)
  end
  
  def setDbl(idx:int, val:double):void
    set(idx, val)
  end
  
  def setFlt(idx:int, val:float):void
    set(idx, val)
  end
  
  def setStr(idx:int, val:String):void
    set(idx, val)
  end
  
  def setObj(idx:int, val:Object):void
    set(idx, val)
  end        
end
