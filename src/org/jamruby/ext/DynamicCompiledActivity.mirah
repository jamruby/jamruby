package org.jamruby.ext

import org.jamruby.ext.JamCompiledActivity

class DynamicCompiledActivity < JamCompiledActivity 
  def onBeforeInit():void  
    setProgram "#{root}/lib/dynamic.rb"
    
    @source = false
    
    if getIntent.getExtras != nil
      setProgram getIntent.getStringExtra("org.jamruby.ext.dynamic.MAIN")
      @source = true
    end
  end
  
  def loadMain:void
    if @source
      super
      return
    end
    
    main.loadScript(program)
  end   
end
