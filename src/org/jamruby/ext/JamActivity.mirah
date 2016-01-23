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
    
    @top_self = RubyObject.new(jamruby.state.nativeObject, MRuby.topSelf(jamruby.state))
  end
  
  def root:String
    Environment.getExternalStorageDirectory.toString+"/jamruby/"+@cls.getPackage.getName
  end
  
  def jamruby
    @jamruby
  end
  
  def setActivityClass c:Class
    @cls = c
  end 
  
  def self.getInstance():JamActivity
    @@instance
  end
  
  def self.toast a:Activity, m:String
    t = Toast.makeText(a, m, 500)
    t.show
    return t
  end
  
  def loadCompiledFull mrb:long, pth:String
    Log.i("jamapp", "mrbib: #{pth}")
    r = MRuby.loadIrep(mrb, pth)
    Log.i("jamapp", "mrbib: #{pth} OK?")    
    return r
  end
  
  def loadScriptFull(mrb:long, pth:String)
    script = Util.readFile(pth)
    Log.i("jamapp",  r = MRuby.loadString(mrb, script).toString)
    return r
  end
  
  def loadScript mrb:State, pth:String
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
    topSelfCall("on_start")
  end
  
  def onPause
    super
    topSelfCall("on_pause")
  end  
  
  def onDestroy
    super
    topSelfCall("on_destroy")
  end  
  
  def onResume
    super
    topSelfCall("on_resume")
  end  
  
  def onRestart
    super
    topSelfCall("on_restart")
  end 
  
  def topSelfCall method:String       
    MRuby.funcall(jamruby.state, MRuby.topSelf(jamruby.state), method, 0)
  end
  
  def l= b:boolean
    @l = b
  end
  
  synchronized def sendMain(m:String, ol:ObjectList):void
    while @l; end
    @l=true
    jamruby = @jamruby
    a=self
    ts = @top_self
    runOnUiThread do
      ts.send m, ol
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
