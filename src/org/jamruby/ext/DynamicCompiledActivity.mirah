package org.jamruby.ext

import org.jamruby.ext.JamCompiledActivity

class DynamicCompiledActivity < JamCompiledActivity 
  def onBeforeInit():void  
    setProgram "#{root}/lib/dynamic.rb"
    
    @source = false
    
    if getIntent.getExtras != nil
      setProgram path=getIntent.getStringExtra("org.jamruby.ext.dynamic.MAIN")
      main.jamruby.loadString("$:.unshift(File.expand_path(File.dirname('#{path}'))) unless $:.include?(File.dirname('#{path}')) || $:.include?(File.expand_path(File.dirname('#{path}')))")
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
