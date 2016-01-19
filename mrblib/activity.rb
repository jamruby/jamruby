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
  
  handler.on :post do |m, *o|
    send m, *o
  end  
rescue => e
  JAVA::Android::Util::Log.e("activity.mrb", "Error: #{e}")
  $r = e
end
