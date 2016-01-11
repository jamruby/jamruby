package org.jamruby.ext

import java.lang.reflect.Field
import org.jamruby.ext.Util
class FieldHelper
  @@TEST=3
  def self.getField(cls:Class, name:String):Integer
  begin
    return Integer(cls.getField(name).get(nil));
  rescue => e
    Util.p e
    return nil
  end
  end
end
