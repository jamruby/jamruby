package org.jamruby.ext

import org.jamruby.ext.JamActivity

class DynamicActivity < JamActivity 
  def onBeforeInit():void  
    setProgram "#{root}/lib/dynamic.rb"
    
    if getIntent.getExtras != nil
      setProgram getIntent.getStringExtra("org.jamruby.ext.dynamic.MAIN")
    end
  end
end
