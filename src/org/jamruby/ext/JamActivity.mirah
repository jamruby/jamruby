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
    
    loadCompiled("#{root}/mrblib/jamruby.mrb")
    loadCompiled("#{root}/mrblib/activity.mrb")  
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
  
  def loadCompiled pth:String
    Log.i("jamapp", "mrbib: #{pth}")
    MRuby.loadIrep(jamruby.state, pth)
    Log.i("jamapp", "mrbib: #{pth} OK?")    
  end
  
  def loadScript(pth:String)
    script = Util.readFile(pth)
    Log.i("jamapp", jamruby.loadString(script).toString)
  end
  
  def checkInstall:boolean
    File.new(root).exists
  end
  
  def install
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
end  
