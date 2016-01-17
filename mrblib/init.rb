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
java.import "java.lang.Class"
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

module JamRuby
  class Proxy
    def self.set_class_path path
      @class_path = path
    end
    
    def self.get_class_path
      @class_path
    end
    
    def initialize &b
      set &b
      
      @proxy=proxy(self.class.get_class_path) do |*o|
        @b.call(*o) if @b
      end
    end
    
    def jobj
      @proxy
    end
    
    def set &b
      @b = b
    end
  end
  
  class Runnable < Proxy
    set_class_path "java.lang.Runnable"
  end
  
  class OnClickListener < Proxy
    set_class_path "android.view.View$OnClickListener"
  end
end
