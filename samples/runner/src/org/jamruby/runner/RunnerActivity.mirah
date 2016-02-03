package org.jamruby.runner

import org.jamruby.ext.JamActivity
import org.jamruby.ext.Util

import java.io.File
import java.io.InputStream
import android.app.ActivityManager
import android.os.Environment
import android.content.Context

class RunnerActivity < JamActivity    
  def onCreate state
    @base = "#{Environment.getExternalStorageDirectory.toString}/jamruby/scripts/org.jamruby.runner/samples"
    
    super
  end
  
  def onInstall
    File.new(base).mkdirs
  
    am = getAssets();
 
    inputStream = am.open("scripts/custom_view.rb");
    Util.createFileFromInputStream("#{base}/custom_view.rb", inputStream);
    
    inputStream = am.open("scripts/thread.rb");
    Util.createFileFromInputStream("#{base}/thread.rb", inputStream);
    
    inputStream = am.open("scripts/multi_progress.rb");
    Util.createFileFromInputStream("#{base}/multi_progress.rb", inputStream);
    
    inputStream = am.open("scripts/download.rb");
    Util.createFileFromInputStream("#{base}/download.rb", inputStream);
    
    inputStream = am.open("scripts/list_view.rb");
    Util.createFileFromInputStream("#{base}/list_view.rb", inputStream);    
  end
  
  def onBeforeInit():void
    if !File.new(base).exists
      onInstall()
    end
  end
  
  def getBaseDir
    @base
  end
end
