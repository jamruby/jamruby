package org.jamruby.ext

import java.lang.reflect.Field
import org.jamruby.ext.Util
class FieldHelper
  @@TEST=3
  def self.getField(cls:Class, name:String):Integer
  begin
    Util.p "field: #{name}"
    return Integer(cls.getField(name).get(nil));
  rescue => e
    Util.p "FieldError: #{e}"
    return nil
  end
  end
  
  def self.hasField(cls:Class, name:String):boolean
  begin  
    cls.getField(name)
    return true
  rescue => e
    Util.p e
    return false
  end
  end
end
