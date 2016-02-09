package org.jamruby.ext

import org.jamruby.ext.JamActivity

class DynamicActivity < JamActivity 
  def onBeforeInit():void  
    setProgram "#{root}/lib/dynamic.rb"
    
    if getIntent.getExtras != nil
      setProgram path=getIntent.getStringExtra("org.jamruby.ext.dynamic.MAIN")
      main.jamruby.loadString("$:.unshift(File.expand_path(File.dirname('#{path}'))) unless $:.include?(File.dirname('#{path}')) || $:.include?(File.expand_path(File.dirname('#{path}')))")
    end
  end
end
