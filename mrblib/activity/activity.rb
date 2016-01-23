begin
  java.import "android/app/Activity"
  java.import "android/widget/Toast"
  java.import "android/os/Handler"
  java.import "android/R"
  java.import "org/jamruby/ext/JamActivity"
 

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
    def toast str, len = 500
      tst = Android::Widget::Toast.makeText activity, str, len
      tst.show
      tst
    end

    def activity
      Org::Jamruby::Ext::JamActivity.getInstance
    end
  end 

rescue => e
  JAVA::Android::Util::Log.e("activity.mrb", "Error: #{e}")
  $r = e
end
