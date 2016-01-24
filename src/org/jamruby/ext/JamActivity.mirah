package org.jamruby.ext

import android.os.Bundle
import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.widget.Toast
import android.util.Log
import java.io.File
import java.io.InputStream

import org.jamruby.core.Jamruby
import org.jamruby.mruby.MRuby
import org.jamruby.mruby.State
import org.jamruby.mruby.Value
import org.jamruby.mruby.GC
import Util
import RubyObject

class JamActivity < Activity
  @@instance = JamActivity(nil)
  def onCreate state 
    super state
    
    if !checkInstall
      install
    end
    
    @@instance = self
    
    @jamruby = Jamruby.new
  
    loadCompiled(jamruby.state, "#{root}/mrblib/activity.mrb") 
    
    @top_self   = RubyObject.new(jamruby.state.nativeObject, MRuby.topSelf(jamruby.state))
    @_self_     = RubyObject(nil)
    
    init()
    
    ol = ObjectList.create
    ol.addObj state
    
    _self_.send "on_create", ol
  end
  
  def root:String
    Environment.getExternalStorageDirectory.toString+"/jamruby/"+self.getClass.getPackage.getName
  end
  
  def jamruby
    @jamruby
  end
  
  def onBeforeInit():void
  
  end
  
  def init():void
    onBeforeInit()
  
    result = loadScript(jamruby.state, "#{root}/main.rb")
    Util.p result.toString
    result  = jamruby.loadString("p '#{root}'; begin; __JAM_ACTIVITY__ = Main.new; $activity = __JAM_ACTIVITY__; p $activity; $activity; rescue => e; p e; nil; end")
    Util.p result.toString
    @_self_ = RubyObject.new(jamruby.state.nativeObject, result)
    Util.p _self_.send("to_s", ObjectList.create).toString
    Util.p _self_.toString
  end
  
  def getActivityClass
    self.getClass
  end
  
  def self.getInstance():JamActivity
    @@instance
  end
  
  def toast m:String
    Util.toast m
  end  
  
  def toast2 m:String
    Util.toast2 m
  end
  
  def loadCompiledFull mrb:long, pth:String
    Log.i("jamapp", "mrbib: #{pth}")
    r = MRuby.loadIrep(mrb, pth)
    Log.i("jamapp", "mrbib: #{pth} OK?")    
    return r
  end
  
  def loadScriptFull(mrb:long, pth:String):Value
    script = Util.readFile(pth)
    Log.i("jamapp",  (r = MRuby.loadString(mrb, script)).toString)
    return r
  end
  
  def loadScript(mrb:State, pth:String):Value
    loadScriptFull mrb.nativeObject, pth
  end
  
  def loadCompiled mrb:State, pth:String
    loadCompiledFull mrb.nativeObject, pth
  end
  
  def checkInstall:boolean
    File.new(getFilesDir.toString+"/i").exists
  end
  
  def onStart
    super
    selfCall("on_start")
  end
  
  def onPause
    super
    selfCall("on_pause")
  end  
  
  def onDestroy
    super
    selfCall("on_destroy")
  end  
  
  def onResume
    super
    selfCall("on_resume")
  end  
  
  def onRestart
    super
    selfCall("on_restart")
  end 
  
  def topSelfCall method:String       
    @top_self.send method, ObjectList.create
  end
  
  def selfCall method:String       
    @_self_.send method, ObjectList.create
  end  
  
  def l= b:boolean
    @l = b
  end
  
  synchronized def rubySendMain(m:String, ol:ObjectList):void
    while @l; end
    @l=true
    a=self
    ts = @top_self
    runOnUiThread do
      ts.send m, ol
      a.l=false
    end
    while @l; end
  end
  
  synchronized def rubySend(m:String, ol:ObjectList):void
    while @l; end
    @l=true
    a=self
    s = @_self_
    runOnUiThread do
      s.send m, ol
      a.l=false
    end
    while @l; end
  end  
  
  synchronized def rubySendWithSelfFromReturn(fun:String, m:String, ol:ObjectList):void
    while @l; end
    @l=true
    jamruby = @jamruby
    a=self
    ts = @top_self
    runOnUiThread do
      value = ts.send fun, ObjectList.create
      RubyObject.new(jamruby.state.nativeObject, value).send m, ol
      a.l=false
    end
    while @l; end
  end  
  
  def install
    File.new("#{getFilesDir}/i").mkdir
    File.new("#{root}").mkdirs
    File.new("#{root}/mrblib").mkdirs  
      
    am = getAssets();
    inputStream = am.open("main.rb");
    Util.createFileFromInputStream("#{root}/main.rb", inputStream);
    
    inputStream = am.open("mrblib/core.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/core.mrb", inputStream);   

    inputStream = am.open("mrblib/jamruby.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/jamruby.mrb", inputStream);  
    
    inputStream = am.open("mrblib/thread.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/thread.mrb", inputStream);      
    
    inputStream = am.open("mrblib/activity.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/activity.mrb", inputStream); 
  end

  def saveArena(mrb:long):int
    return GC.saveArena(mrb)
  end 
  
  def saveArena(mrb:long, i:int):void
    GC.restoreArena(mrb, i)
  end   

  def self.initThread(mrb:long):void
    getInstance.loadCompiledFull(mrb, "#{getInstance.root}/mrblib/core.mrb")
    getInstance.loadCompiledFull(mrb, "#{getInstance.root}/mrblib/jamruby.mrb")  
    getInstance.loadCompiledFull(mrb, "#{getInstance.root}/mrblib/thread.mrb")               
  end
end  
