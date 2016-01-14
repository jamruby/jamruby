# Handle messaging across Threads

begin
  TOP_MRB_HANDLER_PROC = Proc.new  do |i,*o|
    begin
      handler.dispatch i, *o
    rescue => e
    end
  end
  
  TOP_MRB_HANDLER =  proxy("org.jamruby.ext.MessageRunner", &TOP_MRB_HANDLER_PROC)
  
  activity.setHandler(
    TOP_MRB_HANDLER
  )  
  
  class Object
    alias :__jam_require__ :require
    def require w
      q = w.split(".").last
      if q == "rb"
        activity.loadScript w
      elsif q == "mrb"
        activity.loadCompiled w
      else
        __jam_require__ w
      end
    end
  end
  
  require "/sdcard/jamruby/mrblib/ui.mrb"
rescue => e
  JAVA::Android::Util::Log.e("activity.mrb", "Error: #{e}")
  $r = e
end
