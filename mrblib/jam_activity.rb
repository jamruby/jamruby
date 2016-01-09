begin
  TOP_MRB_HANDLER_PROC = Proc.new  do |i,*o|
    p "thread: #{i} #{o}"
    begin
      handler.dispatch i, *o
    rescue => e
      p "thread: #{e}"
    end
  end
  
  TOP_MRB_HANDLER =  proxy("org.jamruby.ext.MessageRunner", &TOP_MRB_HANDLER_PROC)
  
  activity.setHandler(
    TOP_MRB_HANDLER
  )  
rescue => e
  Android::Util::Log.e("jam_activity.mrb", "Error: #{e}")
  $r = e
end
