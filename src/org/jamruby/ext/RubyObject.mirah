package org.jamruby.ext

import org.jamruby.ext.Util
import org.jamruby.ext.ObjectList
import org.jamruby.mruby.State
import org.jamruby.mruby.MRuby
import org.jamruby.mruby.Value


class InvokeResult
  def initialize
    @error           = false
    @error_message   = ""
    @result          = Value(nil)
    @error_detail    = ""
    @error_object    = RubyObject(nil)
    @error_backtrace = ObjectList(nil)
    
    @empty_backtrace    = String[1]
    @empty_backtrace[0] = ""
  end
  
  def error
    @error
  end
  
  def setError bool:boolean
    @error = true
  end
  
  def getErrorObject
    @error_object
  end
  
  def setErrorObject err:RubyObject
    @error_object = err
  end  
  
  def getErrorMessage
    @error_message
  end
  
  def setErrorMessage msg:String
    @error_message = msg
  end
  
  def getErrorDetail
    @error_detail
  end
  
  def setErrorDetail str:String
    @error_detail = str
  end
  
  def getErrorBacktrace():String[]
    if @error_backtrace == nil
      return @empty_backtrace
    end
    
    backtrace = String[@error_backtrace.size]
        
    i = 0
    
    @error_backtrace.each do |m|
      backtrace[i] = String(m)
      i += 1
    end
    
    backtrace
  end
  
  def setErrorBacktrace ol:ObjectList
    @error_backtrace = ol
  end    
  
  def getResult
    @result
  end
  
  def setResult result:Value
    @result = result
  end
end

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

  def send(name:String, ol:ObjectList):InvokeResult
    va = Value[ol.size+2]
    i = 1
    
    va[0] = Util.toValue(mrb, name)
    va[1] = Util.toValue(mrb, ir = InvokeResult.new())
    
    ol.each do |a|
      i+=1
      va[i] = Util.toValue(mrb, a)
    end
    
    ir.setResult(MRuby.funcallArgv(mrb, ins, "send_with_result", ol.size+2, va))
    
    return ir
  end
end
