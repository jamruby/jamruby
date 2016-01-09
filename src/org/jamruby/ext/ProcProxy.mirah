package org.jamruby.ext

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy
import java.lang.reflect.InvocationHandler

import java.util.ArrayList
import ObjectList
import Util
import org.jamruby.mruby.MRuby
import org.jamruby.mruby.Value
import org.jamruby.mruby.State

class ProcProxy
  def self.proxy(str:String, mrb:long, proc:Value):Object
    handler = ProcProxyInvocationHander.new(State.new(mrb), proc);
    ca = Class[1]
    ca[0] = Class.forName(str)
    Object(Proxy.newProxyInstance(ca[0].getClassLoader(),
                            ca,
                            InvocationHandler(handler)));                 
  end
end

class ProcProxyInvocationHander
 implements InvocationHandler
  
  def initialize mrb:State, proc:Value
    super();
    @proc = proc;
    @mrb = mrb;
  end
  
  def invoke(proxy:Object, method:Method, args:Object[]):Object 
      if args[0].kind_of?(ArrayList) and args.length == 1    
        va = Util.arrayListToValueArray(mrb, ArrayList(args[0]))
        
        return MRuby.funcallArgv(mrb, proc, "call", va.length, va);
      end
      
      va = Util.objectArrayToValueArray(mrb, args)
      
      return MRuby.funcallArgv(mrb, proc, "call", va.length, va);
  end
end
