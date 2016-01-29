package org.jamruby.ext

import android.os.Bundle
import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.widget.Toast
import android.util.Log
import android.os.Process

import java.io.File
import java.io.InputStream

import org.jamruby.core.Jamruby
import org.jamruby.mruby.MRuby
import org.jamruby.mruby.State
import org.jamruby.mruby.Value
import org.jamruby.mruby.GC

import Util
import RubyObject
import org.jamruby.ext.MainHandle
import org.jamruby.ext.MainDispatch

class JamActivity < Activity
  implements MainDispatch
  
  @@instance = JamActivity(nil)
  
  def onCreate state 
    super state
    
    @root = Environment.getExternalStorageDirectory.toString+"/jamruby/"+self.getClass.getPackage.getName    
    
    
    @didInstall = false;
    
    if !checkInstall
      install
    end
    
    @@instance = self
    @main      = MainHandle.new(self, root)
    
    @main.core_libs.add "#{root}/mrblib/core.mrb"
    @main.core_libs.add "#{root}/mrblib/jamruby.mrb"
    @main.core_libs.add "#{root}/mrblib/thread.mrb"        
    
    @_self_    = RubyObject(nil)
  
    @program = "#{root}/main.rb"
    
    init()

    ol = ObjectList.create
    ol.addObj state
    
    _self_.send "on_create", ol
  end
  
  def root
    @root
  end
  
  def main
    @main
  end
  
  def onBeforeInit():void
    
  end
  
  def init():void
    Util.p "MSG: MainHandle#init"
    main.init  
    Util.p "EMSG"
    
    Util.p "MSG: #onBeforeInit"
    onBeforeInit()
    Util.p "EMSG"
    
    MRuby.defineConst(main.jamruby.state, MRuby.classGet(main.jamruby.state, "Object"), "JAM_ACTIVITY", Util.toValue(main.jamruby.state, self))
    
    
    Util.p "MSG: Load Activity Library"
    main.loadCompiled("#{root}/mrblib/activity.mrb")
    Util.p "EMSG"
    
    Util.p "MSG: #loadMain"
    loadMain()
    Util.p "EMSG"
    
    Util.p "MSG: Create Ruby Activity"
    result  = main.jamruby.loadString("p $0; begin; ACTIVITY = Main.new; p ACTIVITY; ACTIVITY; rescue => e; p e; nil; end")
    Util.p result.toString
    @_self_ = RubyObject.new(main.jamruby.state, result)
    Util.p _self_.send("to_s", ObjectList.create).toString
    Util.p _self_.toString  
    Util.p "EMSG"  
  end
  
  def getActivityClass
    self.getClass
  end
  
  def loadScript(pth:String):Value
    main.loadScript pth
  end
  
  def loadCompiled pth:String
    main.loadCompiled pth
  end
  
  def checkInstall:boolean
    File.new(getFilesDir.toString+"/i").exists
  end
  
  def selfCall fun:String
    _self_.send fun, ObjectList.create
  end
  
  synchronized def selfCallArgv fun:String, ol:ObjectList
    s = _self_
    runOnUiThread do
      s.send fun, ol
    end
  end 
  
  synchronized def runProcOnMainThread(v:Value):void
    state = main.jamruby.state
    runOnUiThread do
      i = MRuby.funcall(state, v, "__from_java__", 0)
      MRuby.funcall(state, i, "__jam_call__", 1, MRuby.arrayNew(state))
    end
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
    
    Process.killProcess(Process.myPid())
  end  
  
  def onResume
    super
    selfCall("on_resume")
  end  
  
  def onRestart
    super
    selfCall("on_restart")
  end 
  
  def install
    @didInstall = true

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
    
    onInstall()
  end
  
  def onInstall():void

  end
  
  def runOnMainThread(r:Runnable):void
    runOnUiThread r
  end
  
  def setProgram path:String
    @program = path
  end
  
  def program
    @program
  end
  
  def loadMain:void
    main.loadScript(program)
  end       
end  


class JamCompiledActivity < JamActivity
  def onBeforeInit:void
    setProgram "#{root}/main.mrb"
  end
  
  def loadMain:void
    main.loadCompiled program
  end
end
