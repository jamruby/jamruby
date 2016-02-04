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
import android.view.Gravity
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

    trace.setGravity(Gravity.TOP | Gravity.LEFT);

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
    @script_dir = "#{Environment.getExternalStorageDirectory.toString}/jamruby/scripts/#{self.getClass.getPackage.getName}"
    
    
    @didInstall = false;
    
    if !checkInstall
      install
    end
    
    @@instance = self
    @main      = MainHandle.new(self, root)
    
    @main.core_libs.add "#{root}/mrblib/core.mrb"
    @main.core_libs.add "#{root}/mrblib/base.mrb"
    @main.core_libs.add "#{root}/mrblib/common.mrb"        
    
    @_self_    = RubyObject(nil)
    @create    = false
    @program   = "#{root}/main.rb"

    @prog_result = Value(nil)

    init
    
    if _self_ != nil
      ol = ObjectList.create
      ol.addObj state

      r = _self_.send "on_create", ol
    
      if r.error
        setContentView DisplayError.new(self, r.getErrorMessage, r.getErrorDetail, r.getErrorBacktrace)
      else
        @create = true
      end
    else
      if @prog_result != nil
        bt = String[1]
        bt[0] = ""
        Util.p "no Main"
        setContentView DisplayError.new(self, "Program did not define class: Main", MRuby.funcall(main.jamruby.state, @prog_result, "to_s", 0).asString, bt)
      end
    end
  rescue => e
    empty = String[1]
    empty[0] = ""
    setContentView DisplayError.new(self, "BadError, >:(", "#{e}", empty)
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
    main.jamruby.loadString("$:.unshift(File.expand_path('#{main.root}/mrblib')) unless $:.include?('#{main.root}/mrblib') || $:.include?(File.expand_path('#{main.root}/mrblib'))")

    Util.p "EMSG"
    
    Util.p "MSG: #onBeforeInit"
    onBeforeInit()
    Util.p "EMSG"
    
    MRuby.defineConst(main.jamruby.state, MRuby.classGet(main.jamruby.state, "Object"), "JAM_ACTIVITY", Util.toValue(main.jamruby.state, self))
    
    
    Util.p "MSG: Load Activity Library"
    main.loadCompiled("#{root}/mrblib/jamruby/app.mrb")
    Util.p "EMSG"
    
    Util.p "MSG: #loadMain"
    @prog_result = loadMain()
    Util.p "EMSG"
    
    Util.p "MSG: Create Ruby Activity"
    result  = main.jamruby.loadString("begin; ACTIVITY = Main.new; ACTIVITY; rescue => e; p e; false; end")

    if result.isFalse
      Util.p "JAM_ACTIVITY: Unable to create activity"
    else
      @_self_ = RubyObject.new(main.jamruby.state, result)
      Util.p _self_.send("to_s", ObjectList.create).getResult.asString
      Util.p _self_.toString
    end
    
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
    if !File.new("#{@script_dir}").exists
      File.new("#{@script_dir}").mkdirs    
      File.new("#{@script_dir}/scripts").mkdirs
    end
  
    File.new(getFilesDir.toString+"/i").exists || File.new(root).exists
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
    selfCall("on_start") if @create
  end
  
  def onPause
    super
    selfCall("on_pause") if @create
  end  
  
  def onDestroy
    super
    if @create
      if !selfCall("on_destroy")
        Process.killProcess(Process.myPid())
      end
    else
      Process.killProcess(Process.myPid())
    end
  end  
  
  def onResume
    super
    selfCall("on_resume") if @create
  end  
  
  def onRestart
    super
    selfCall("on_restart") if @create
  end
  
  def onBackPressed
    if @create
      if selfCall("on_back_pressed")
        super
      end
    end
  end    
  
  def install
    @didInstall = true

    File.new("#{getFilesDir}/i").mkdir
    File.new("#{root}").mkdirs
    File.new("#{root}/mrblib").mkdirs  
    File.new("#{root}/mrblib/jamruby").mkdirs    
    File.new("#{root}/lib").mkdirs  
    File.new("#{@script_dir}").mkdirs      
    File.new("#{@script_dir}/scripts").mkdirs  
      
    am = getAssets();
    inputStream = am.open("main.rb");
    Util.createFileFromInputStream("#{root}/main.rb", inputStream);
    
    copyAssets("mrblib", root)  
    copyAssets("lib", root)  
    copyAssets("scripts", @script_dir)          
    
    onInstall()
  end
  
  def getScriptsDir
    @script_dir+"/scripts"
  end
  
  def copyAssets(path:String, dest:String):boolean
    begin
      am = getAssets();
      list = getAssets().list(path);
      if (list.length > 0)
        # This is a folder
        list.each do |file|
          if (!copyAssets(path + "/" + file, dest))
            return false;
          end
        end
      else
        Util.p "Copy: #{path}"
        inputStream = am.open(path);
        Util.createFileFromInputStream("#{dest}/#{path}", inputStream); 
      end
    rescue => e
      return false;
    end

    return true; 
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
  
  def loadMain:Value
    main.loadScript(program)
  end       
end  


class JamCompiledActivity < JamActivity
  def onBeforeInit:void
    setProgram "#{root}/main.mrb"
  end
  
  def loadMain:Value
    main.loadCompiled program
  end
end
