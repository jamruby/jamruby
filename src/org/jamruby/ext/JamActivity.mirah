package org.jamruby.ext

import android.os.Bundle
import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.widget.Toast
import android.widget.ScrollView
import android.widget.LinearLayout
import android.widget.LinearLayout.LayoutParams
import android.widget.EditText
import android.content.Context
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

class DisplayError < LinearLayout
  def initialize c:Context, msg:String, detail:String, backtrace:String[]
    super(c)
    
    setOrientation LinearLayout.VERTICAL
    
    addView header = EditText.new(c), LayoutParams.new(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT, float(0.1));
    addView trace  = EditText.new(c),  LayoutParams.new(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT, float(1.0));

    header.setMaxLines 1 
    header.setHorizontallyScrolling(true);

    trace.setHorizontallyScrolling(true);    

    header.setText "Error: #{msg}"
    
    trace_msg = "#{detail}"
    
    backtrace.each do |m|
      trace_msg += "\n#{String(m)}"
    end
    
    trace.setText trace_msg
  end
end

class JamActivity < Activity
  implements MainDispatch
  
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
    @create    = false
    @program   = "#{root}/main.rb"

    init
    
    ol = ObjectList.create
    ol.addObj state
    
    r = _self_.send "on_create", ol
    
    if r.error
      setContentView DisplayError.new(self, r.getErrorMessage, r.getErrorDetail, r.getErrorBacktrace)
    else
      @create = true
    end
  rescue => e
    empty = String[1]
    empty[0] = ""
    setContentView DisplayError.new(self, "#{e}", "", empty)
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
    Util.p _self_.send("to_s", ObjectList.create).getResult.toString
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
  
  def selfCall(fun:String):boolean
    r = _self_.send fun, ObjectList.create
    r.getResult.isTrue
  end
  
  synchronized def selfCallArgv fun:String, ol:ObjectList
    s = _self_
    runOnUiThread do
      s.send fun, ol
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
    if !selfCall("on_destroy")
      Util.p "destroy"
      Process.killProcess(Process.myPid())
    end
  end  
  
  def onResume
    super
    selfCall("on_resume")
  end  
  
  def onRestart
    super
    selfCall("on_restart")
  end
  
  def onBackPressed
    if selfCall("on_back_pressed")
      super
    end
  end    
  
  def install
    @didInstall = true

    File.new("#{getFilesDir}/i").mkdir
    File.new("#{root}").mkdirs
    File.new("#{root}/mrblib").mkdirs  
    File.new("#{root}/lib").mkdirs     
      
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
  
    inputStream = am.open("lib/dynamic.rb");
    Util.createFileFromInputStream("#{root}/lib/dynamic.rb", inputStream);   
    
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
