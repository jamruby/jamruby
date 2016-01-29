package org.jamruby.ext

import java.lang.Runnable
import java.lang.Thread
import java.util.ArrayList

import RubyObject
import Util
import org.jamruby.core.Jamruby
import org.jamruby.mruby.MRuby
import org.jamruby.mruby.Value
import org.jamruby.mruby.State

class Runner
  implements Runnable
  def initialize t:JamThread, main:MainHandle, ol:ObjectList, proc:RubyObject
    @thread = t
    @proc = proc
    @main = main
    @argv = ol
  end
  
  def run
    @jamruby = Jamruby.new
    MRuby.defineConst(jamruby.state, MRuby.classGet(jamruby.state, "Object"), "JAM_MAIN_HANDLE", Util.toValue(jamruby.state, @main))

    main.initThread jamruby.state

    ary = MRuby.arrayNew jamruby.state
    
    @argv.each do |a|
      MRuby.arrayPush jamruby.state, ary, Util.toValue(jamruby.state, a)
    end
    
    MRuby.threadInit proc.mrb.nativeObject, ary, proc.ins, @jamruby.state.nativeObject
    
    @jamruby.close
  end
end


class JamThread < Thread
  def initialize main:MainHandle, argv:ObjectList, proc:RubyObject
    super Runner.new(self, main, argv, proc)
  end
end


interface MainDispatch do
  def runOnMainThread(r:Runnable):void
  end
end

class MainHandle  
  def initialize main_runner:MainDispatch, root:String
    @jamruby     = Jamruby.new
    @top_self    = RubyObject.new(jamruby.state, MRuby.topSelf(jamruby.state))
    @root        = root
    @main_runner = main_runner
    
    @core_libs = ArrayList.new
    @core_libs.add ""
    @core_libs.remove(0)
  end
  
  def top_self
    @top_self
  end
  
  def init():void
    initMain  
  end
  
  def core_libs
    @core_libs
  end
  
  def jamruby
    @jamruby
  end
  
  def loadCompiled pth:String
    loadCompiledFull jamruby.state.nativeObject, pth  
  end 
  
  def loadScript pth:String
    loadScriptFull jamruby.state.nativeObject, pth  
  end   
  
  def loadCompiledFull mrb:long, pth:String
    Util.p("mrbib: #{pth}")
    r = MRuby.loadIrep(mrb, pth)
    Util.p("mrbib: #{pth} OK?")    
    return r
  end
  
  def loadScriptFull(mrb:long, pth:String):Value
    script = Util.readFile(pth)
    Util.p((r = MRuby.loadString(mrb, script)).toString)
    return r
  end
  
  def topSelfCall method:String       
    @top_self.send method, ObjectList.create
  end
  
  def initMain
    MRuby.defineConst(jamruby.state, MRuby.classGet(jamruby.state, "Object"), "JAM_MAIN_HANDLE", Util.toValue(jamruby.state, self))
    initThread jamruby.state
  end

  def initThread(mrb:State):void
    MRuby.defineConst(mrb, MRuby.classGet(mrb, "Object"), "JAM_THREAD_STATE", Util.toValue(mrb, mrb))
      
    core_libs.each do |l|
      loadCompiledFull mrb.nativeObject, String(l)
    end            
  end
  
  synchronized def rubySendMain(fn:String, ol:ObjectList):void
    ts = top_self

    @main_runner.runOnMainThread do
      ts.send fn, ol
    end
  end
  
  synchronized def rubySendMainBlock(fn:String, ol:ObjectList):void
    ts     = top_self
    q      = true
    
    # result = Value(nil)
    
    @main_runner.runOnMainThread do
      # result = 
      ts.send fn, ol
      
      q = false
    end
    
    while q == true; end
  end  
  
  synchronized def rubySendMainWithSelfFromResult(target:String, fn:String, ol:ObjectList):void
    ts = top_self

    jamruby = @jamruby

    @main_runner.runOnMainThread do
      ins = ts.send target, ObjectList.create
      MRuby.funcallArgv jamruby.state, ins, fn, ol.size, Util.arrayListToValueArray(jamruby.state, ol)
    end
  end  
  
  synchronized def rubySendMainWithSelfFromResultBlock(target:String, fn:String, ol:ObjectList):void
    ts = top_self

    l = true

    jamruby = @jamruby

    @main_runner.runOnMainThread do
      ins = ts.send target, ObjectList.create
      MRuby.funcallArgv jamruby.state, ins, fn, ol.size, Util.arrayListToValueArray(jamruby.state, ol)
      l = false
    end
    
    while l == true; end
  end 
  
  synchronized def transferProc from:RubyObject
    r=Value(nil)
    b = true
    jamruby = @jamruby
    main_runner.runOnMainThread do
      r = MRuby.transferProc from.mrb.nativeObject, from.ins, jamruby.state.nativeObject
      b = false
    end
    while b; end
    return RubyObject.new(from.mrb, r)
  end
  
  synchronized def runProcOnMainThread(ol:ObjectList, fun:RubyObject):void
    state = jamruby.state

    main_runner.runOnMainThread do
      ary = MRuby.arrayNew state
      ol.each do |a|
        MRuby.arrayPush state, ary, Util.toValue(state, a)
      end
      MRuby.funcall(state, fun.ins, "__jam_call__", 1, ary)
    end
  end    
end     
