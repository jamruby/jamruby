package org.hello.mruby

import org.jamruby.ext.JamActivity

class HelloActivity < JamActivity    
  def onCreate(state)
    setActivityClass self.class    
    
    super state
    
    loadScriptFull(jamruby.state.nativeObject, "#{root}/main.rb")
  end
end
