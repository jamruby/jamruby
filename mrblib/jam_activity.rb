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
rescue => e
  JAVA::Android::Util::Log.e("jam_activity.mrb", "Error: #{e}")
  $r = e
end
