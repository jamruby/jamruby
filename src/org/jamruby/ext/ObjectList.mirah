package org.jamruby.ext

import java.util.ArrayList

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
