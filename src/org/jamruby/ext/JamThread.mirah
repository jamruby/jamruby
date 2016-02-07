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

class Handle
  def initialize()
    @jamruby     = Jamruby(nil)
    @top_self    = RubyObject(nil)
    @did_init    = false
  end
  
  def did_init:boolean
    @did_init
  end

  def top_self():RubyObject
    @top_self
  end
  
  def init:void
    @jamruby  = Jamruby.new
    @top_self = RubyObject.new(jamruby.state, MRuby.topSelf(jamruby.state))  
    @did_init = true  
  end
  
  def send(mname:String, ol:ObjectList):InvokeResult
     @top_self.send mname, ol 
  end
  
  def close:void
    @jamruby.close    
  end
  
  
  def jamruby:Jamruby
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
    top_self.send method, ObjectList.create
  end    
end

class SubHandle < Handle
  def initialize main:MainHandle, ol:ObjectList, proc:RubyObject
    super()
  
    @proc = proc
    @main = main
    @argv = ol
  end
  
  def init:void
    super
    
    MRuby.defineConst(jamruby.state, MRuby.classGet(jamruby.state, "Object"), "JAM_MAIN_HANDLE", Util.toValue(jamruby.state, @main))

    main.initThread jamruby.state

    ary = MRuby.arrayNew jamruby.state
    
    @argv.each do |a|
      MRuby.arrayPush jamruby.state, ary, Util.toValue(jamruby.state, a)
    end
    
    MRuby.threadInit proc.mrb.nativeObject, ary, proc.ins, jamruby.state.nativeObject
  end
end

class Runner < SubHandle
  implements Runnable
  def initialize  main:MainHandle, ol:ObjectList, proc:RubyObject
    super main, ol, proc
  end
  
  def run
    init
  
    close    
  end
end


class JamThread < Thread
  def initialize main:MainHandle, argv:ObjectList, proc:RubyObject
    super Runner.new(main, argv, proc)
  end
end


interface MainDispatch do
  def runOnMainThread(r:Runnable):void
  end
end

class MainHandle < Handle
  def initialize main_runner:MainDispatch, root:String    
    super()
  
    @root        = root
    @main_runner = main_runner
    
    @core_libs = ArrayList.new
    @core_libs.add ""
    @core_libs.remove(0)
  end
  
  def root
    @root
  end
  
  def init():void
    super()
    
    initMain  
  end
  
  def core_libs
    @core_libs
  end
  
  def initMain
    MRuby.defineConst(jamruby.state, MRuby.classGet(jamruby.state, "Object"), "JAM_MAIN_HANDLE", Util.toValue(jamruby.state, self))
    initThread jamruby.state
    jamruby.loadString("$:.unshift(File.expand_path('#{root}')) unless $:.include?('#{root}') || $:.include?(File.expand_path('#{root}'))")
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

    state = jamruby.state

    @main_runner.runOnMainThread do
      result = ts.send(target, ObjectList.create)
      if !result.error
        MRuby.funcallArgv state, result.getResult, fn, ol.size, Util.arrayListToValueArray(state, ol)
        return
      end
      
      raise Throwable.new(result.getErrorMessage, result.getErrorDetail)
    end
  end  
  
  synchronized def rubySendMainWithSelfFromResultBlock(target:String, fn:String, ol:ObjectList):void
    ts = top_self

    l = true

    state = jamruby.state

    @main_runner.runOnMainThread do
      result = ts.send(target, ObjectList.create)
      if !result.error
        MRuby.funcallArgv state, result.getResult, fn, ol.size, Util.arrayListToValueArray(state, ol)
        l = false
        return
      end
      
      l = false
      raise Throwable.new(result.getErrorMessage, result.getErrorDetail)
    end
    
    while l == true; end
  end 
  
  synchronized def transferProc from:RubyObject
    r=Value(nil)
    b = true
    state = jamruby.state
    main_runner.runOnMainThread do
      r = MRuby.transferProc from.mrb.nativeObject, from.ins, state.nativeObject
      b = false
    end
    while b; end
    return RubyObject.new(from.mrb, r)
  end
end  

class JavascriptObject < SubHandle 
  def initialize(main:MainHandle, ol:ObjectList, proc:RubyObject)
    super
  end
 
  def send(name:String, params:String):String
    ol = ObjectList.create
    
    if params != nil
      ol.addStr params
    end
    
    result = super name, ol
    
    if result.error
      return "null"
    end
    
    result = RubyObject.new(jamruby.state, result.getResult).send "to_json", ObjectList.create
    
    return result.getResult.asString()
    
    if result.error
      return "null"
    end 
  end

  def dispatch_argv(name:String, params:String):String
    if did_init == false
      init()
    end
    
    result = send name, params 
    
    return result
  end
  
  def dispatch(name:String):String
    if did_init == false
      init()
    end
    
    result = send name, String(nil)
    
    return result
  end  
end   
