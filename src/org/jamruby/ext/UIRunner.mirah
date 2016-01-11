package org.jamruby.ext

import android.view.View
import android.util.Log
import java.lang.Runnable
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy
import java.lang.reflect.InvocationHandler

import ObjectList
import Invoke

class UIRunner
  implements Runnable
  def initialize(as:String, ins:Object, mname:String)
    @as = as
    @ins = ins
    @mname = mname
    @atypes = ObjectList.create
    @args = ObjectList.create
  end
  
  def args
    @args
  end
  
  def atypes
    @atypes
  end
  
  def run():void
    begin
    Invoke.invoke(as, ins, mname, atypes, args)
    rescue => e
      Log.i("jamui", "Error: #{e}")
    end
  end
end
