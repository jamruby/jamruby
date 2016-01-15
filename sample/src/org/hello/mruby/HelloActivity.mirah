package org.hello.mruby

import org.jamruby.ext.JamActivity

class HelloActivity < JamActivity    
  def onCreate(state)
    setActivityClass self.class    
    
    super state
    
    loadScript(jamruby.state, "#{root}/main.rb")
  end
end
