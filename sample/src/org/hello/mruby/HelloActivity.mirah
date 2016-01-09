package org.hello.mruby

import org.jamruby.ext.JamActivity

class HelloActivity < JamActivity    
  def onCreate(state)
    super state
    
    loadScript("/sdcard/sample_jam_application.rb")
  end
end
