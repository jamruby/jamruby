package org.jamruby.ext

import java.lang.Runnable
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
    Invoke.invoke(as, ins, mname, atypes, args)
  end
end
