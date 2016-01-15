java.import "org/jamruby/ext/FieldHelper"
java.import "android/app/Activity"
java.import "android/widget/Toast"
java.import "android/os/Handler"  

java.import "org/jamruby/ext/ObjectList"    
java.import "org/jamruby/ext/Util"  
java.import "org/jamruby/ext/Invoke"
java.import "org/jamruby/ext/UIRunner" 
java.import "org/jamruby/ext/ProcProxy" 
   
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
