package org.jamruby.runner

import org.jamruby.ext.JamActivity

class SpawnedActivity < JamActivity 
  def onBeforeInit():void  
    setProgram "#{root}/spawn.rb"
    
    if getIntent.getExtras != nil
      setProgram getIntent.getStringExtra("org.jamruby.runner.spawned.MAIN")
    end
  end
end
