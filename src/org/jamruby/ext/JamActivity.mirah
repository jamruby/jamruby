import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import android.util.Log

package org.jamruby.ext

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
  def onCreate c
    super c
    
    @@instance = self
    
    @jamruby = Jamruby.new
    
    loadCompiled("/sdcard/jam_activity.mrb")
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
    n = self
    runOnUiThread do   
      script = Util.readFile(pth)

      Log.i("jamapp", n.jamruby.loadString(script).toString)
    end
  end
end
