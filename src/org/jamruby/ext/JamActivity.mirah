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

import Util
import MessengerCallback
import MessageRunner
import MessageHandler

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
    loadCompiled(jamruby.state, "#{root}/mrblib/view.mrb") 
  end
  
  def root:String
    Environment.getExternalStorageDirectory.toString+"/jamruby/"+@cls.getPackage.getName
  end
  
  def setHandler prx:MessageRunner
    @handler = MessageHandler.new(Looper.getMainLooper, MessengerCallback.new(prx))  
  end
  
  def getHandler:MessageHandler
    @handler
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
    Toast.makeText(a, m, 500).show
  end
  
  def loadCompiledFull mrb:long, pth:String
    Log.i("jamapp", "mrbib: #{pth}")
    MRuby.loadIrep(mrb, pth)
    Log.i("jamapp", "mrbib: #{pth} OK?")    
  end
  
  def loadScriptFull(mrb:long, pth:String)
    script = Util.readFile(pth)
    Log.i("jamapp", MRuby.loadString(mrb, script).toString)
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
  
  def install
    File.new("#{getFilesDir}/i").mkdir
    File.new("#{root}").mkdirs
    File.new("#{root}/mrblib").mkdirs  
      
    am = getAssets();
    inputStream = am.open("main.rb");
    Util.createFileFromInputStream("#{root}/main.rb", inputStream);
    
    inputStream = am.open("mrblib/jamruby.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/jamruby.mrb", inputStream);   
    
    inputStream = am.open("mrblib/activity.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/activity.mrb", inputStream); 
    
    inputStream = am.open("mrblib/view.mrb");
    Util.createFileFromInputStream("#{root}/mrblib/view.mrb", inputStream);          
  end

  def self.initThread(mrb:long):void
    getInstance.loadCompiledFull(mrb, "#{getInstance.root}/mrblib/jamruby.mrb")  
  end
end  
