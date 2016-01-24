package org.hello.mruby

import org.jamruby.ext.JamActivity

# Demonstrates creating an activity created in Ruby
#
# There isnt really much you have to do ...

# Subclass org.jamruby.ext.JamActivity, thats it.
class HelloActivity < JamActivity    
  # def onCreate state
  #   # maybe do stuff
  #  
  #   super # must call super
  #
  #   # maybe do (more) stuff
  # end

  # # Called after onCreate and just before `<root>/main.rb` is loaded and the ruby JamRuby::Activity (::Main) is initialized
  # def onBeforeInit():void
  #   # do stuff
  # end
  
  # # Below is a template where <Action> is one of: Pause|Resume|Create|Destroy|Start|Stop|Restart
  # #                     where <action> is one of: pause|resume|create|destroy|start|stop|Restart
  # #
  # def on<Action>():void
  #   # maybe do stuff
  #   # super # optional, if called will call `on_<action>` on the ruby JamRuby::Activity (::Main) instance
  #   # maybe do (more) stuff
  # end
end
