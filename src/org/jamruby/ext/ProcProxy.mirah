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
  
  def mrb
    @mrb
  end
  
  def proc
    @proc
  end
  
  def invoke(proxy:Object, method:Method, args:Object[]):Object
    ins = self
    a=ObjectList.create
    a.addStr method.getName
  
    args.each do |o| 
      a.addObj o
    end
             

      if a.size == 1 and a.get(0).kind_of?(ArrayList)    
        va = Util.arrayListToValueArray(ins.mrb, ArrayList(a.get(0)))
        
        MRuby.funcallArgv(ins.mrb, ins.proc, "call", va.length, va);
      else
        va = Util.arrayListToValueArray(ins.mrb, a)
      
        MRuby.funcallArgv(ins.mrb, ins.proc, "call", va.length, va);
      end

  
    nil
  end
end
