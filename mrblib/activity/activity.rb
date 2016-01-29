begin
  java.import "android/widget/Toast"
  java.import "android/R"
  java.import "org/jamruby/ext/JamActivity"
  java.import "android/content/Intent"
  java.import "org/jamruby/ext/JamIntent"

   
  module JamRuby
    class Intent < Android::Content::Intent
      def putExtra key, val
        jc = native.jclass

        paths = ["Ljava/lang/String;"]
        
        if val.is_a?(String)
          paths[1] = paths[0]
        elsif val.is_a? Integer
          paths[1] = "I"
        elsif val.is_a? Float
          paths[1] = "F"
        else
          raise ArgumentError.new("bad value")                   
        end

        im = jc.get_method("putExtra", "(#{paths.join()})Landroid/content/Intent;")
        jc.call native, im, key, val
      end 
      
      def self.createComponent *o
        ins = wrap Org::Jamruby::Ext::JamIntent.createComponent(*o).native
      end
      
      def self.new *o
        _new *o
      end
    end
  end

  module JamRuby
    module NativeActivity
      def init act
        path = act.getClass.getName.split(".").join("/")
        cls = java.import(path) 
        @native = act.native
        m = Module.new
        
        m.module_eval do
          cls::WRAP::SIGNATURES.each do |s|
            unless act.respond_to?(:"#{s[0]}")
              define_method s[0] do |*o|
                cls.wrap(native).send s[0], *o
              end
            end
          end
        end
        
        extend m
      end
    end
  
    class Activity < Org::Jamruby::Ext::JamActivity
      include NativeActivity
      def initialize
        init Org::Jamruby::Ext::JamActivity.wrap(JAM_ACTIVITY)
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
        p :stop
        # ...
      end
      
      def on_start
        # ...
      end
      
      def on_restart
        # ...
      end
      
      def on_destroy

      end
      
      # Called when the Activity is created.  
      # Typically the main entry point
      #
      # @param [Bundle] state
      def on_create state
        # ...
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
