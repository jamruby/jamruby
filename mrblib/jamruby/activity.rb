begin
  java.import "org/jamruby/ext/JamActivity"

  module JamRuby
    module NativeActivity
    end
  
    class Activity < Org::Jamruby::Ext::JamActivity     
      include NativeActivity
      
      def initialize
        @native = JAM_ACTIVITY.cast
      end
      
      def self.new
        _new()
      end
      
      def on_pause
        # ...
      end
      
      def on_resume
        # ...
      end
      
      def on_stop
        # ...
      end
      
      def on_start
        # ...
      end
      
      def on_restart
        # ...
      end
      
      # @return [true] to not kill process
      def on_destroy
        false
      end
      
      # Called when the Activity is created.  
      # Typically the main entry point
      #
      # @param [Bundle] state
      def on_create state
        # ...
      end
      
      def on_back_pressed
        true
      end
    end
  end
 
  module Kernel
    # Toasts a message
    #
    # @param [String] str
    def toast str
      tst = Android::Widget::Toast.makeText activity, str, 1000
      tst.show
      tst
    end

    # Gets the Activity
    #
    # @return [JamRuby::Activity]
    def activity
      ACTIVITY
    end
  end 

rescue => e
  JAVA::Android::Util::Log.e("activity.mrb", "Error: #{e}")
  $r = e
end
