package org.jamruby.ext

import org.jamruby.ext.Util
import org.jamruby.ext.ObjectList
import org.jamruby.mruby.State
import org.jamruby.mruby.MRuby
import org.jamruby.mruby.Value


class RubyObject
  def initialize mrb:State, ins:Value
    @mrb = mrb
    @ins = ins
  end
  
  def mrb
    @mrb
  end 
  
  def ins
    @ins
  end
  
  def self.create mrb:State, ins:Value
    RubyObject.new(mrb, ins)
  end

  def send(name:String, ol:ObjectList):Value
    va = Value[ol.size]
    i = -1
    
    ol.each do |a|
      i+=1
      va[i] = Util.toValue(mrb, a)
    end
    
    MRuby.funcallArgv mrb, ins, name, ol.size, va
  rescue => e
    Util.p e.toString
    return MRuby.funcall(mrb, ins, "raise", 1, MRuby.strNew(mrb, e.toString))
  end
end
