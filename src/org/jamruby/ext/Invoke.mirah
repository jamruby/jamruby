package org.jamruby.ext

import ObjectList
import java.lang.reflect.Method;
import android.util.Log


class Invoke
  def self.create(as:String, ins:Object, mname:String, atypes:ObjectList, args:ObjectList):Invoke
    if Class.forName(as).isInstance(ins)
      Log.i("jaminv", "ins is #{as}")
    else
      Log.i("jaminv", "ins #{ins} is not #{Class.forName(as)}")
    end
    
    atypev = Class[args.size];
    argv   = Object[args.size];
    
    i = 0
    
    args.each do |a|   
      atypev[i] = Class.forName(String(atypes.get(i)))
      argv[i]   = a
      i += 1
    end
    
    m   = Class.forName(as).getMethod(mname, atypev);    
    
    Invoke.new(ins, m, argv)
  end
  
  def initialize ins:Object, m:Method, argv:Object[]
    @ins  = ins
    @m    = m
    @argv = argv
  end
  
  def invoke:Object  
    m.invoke(ins, argv);  
  end
  
  def self.invoke(as:String, ins:Object, mname:String, atypes:ObjectList, args:ObjectList):Object
    create(as, ins,mname,atypes,args).invoke
  end
end
