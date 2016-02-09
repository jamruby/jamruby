package org.jamruby.ext

import org.jamruby.ext.JamCompiledActivity

class DynamicCompiledActivity < JamCompiledActivity 
  def onBeforeInit():void  
    setProgram "#{root}/lib/dynamic.rb"
    
    @source = true
    
    if getIntent.getExtras != nil
      setProgram path=getIntent.getStringExtra("org.jamruby.ext.dynamic.MAIN")
      main.jamruby.loadString("$:.unshift(File.expand_path(File.dirname('#{path}'))) unless $:.include?(File.dirname('#{path}')) || $:.include?(File.expand_path(File.dirname('#{path}')))")
      @source = false
    end
  end
  
  def loadMain
    if !@source
      super
    else
      main.loadScript(program)
    end
  end
end
