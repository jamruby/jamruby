begin
  java.import "android/app/Activity"
  java.import "android/widget/Toast"
  java.import "android/os/Handler"
  java.import "android/R"
  java.import "org/jamruby/ext/JamActivity"
 
 
  module JamRuby
    module NativeActivity
    end
  
    class Activity < Org::Jamruby::Ext::JamActivity
      def initialize
        @native = Org::Jamruby::Ext::JamActivity.getInstance.native
        extend JamRuby::NativeActivity
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
      
      def on_destroy
        # ...
      end
      
      def on_create state
        # ...
      end
    end
  end

  class Object
    alias :__jam_require__ :require
    def require w
      q = w.split(".").last
      if q == "rb"
        activity.loadScriptFull __mrb_context__, w
      elsif q == "mrb"
        activity.loadCompiledFull __mrb_context__, w
      else
        __jam_require__ w
      end
    end
  end
 
  module Kernel
    def toast str
      tst = Android::Widget::Toast.makeText activity, str, 1000
      tst.show
      tst
    end

    def activity
      $activity
    end
  end 

rescue => e
  JAVA::Android::Util::Log.e("activity.mrb", "Error: #{e}")
  $r = e
end
