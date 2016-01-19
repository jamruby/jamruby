java.import "org/jamruby/ext/MessageRunner"
java.import "org/jamruby/ext/MessageHandler" 
  
class Org::Jamruby::Ext::MessageHandler
  Callbacks = []
  def on n, &b
    id = nil
    if id = registerMessage(n.to_s)
      Callbacks[id] = b
      return true
    end
    
    raise "RegisterMessageError: could not register #{n}"
  end
  
  def dispatch id, *o 
    if id >=0 and cb=Callbacks[id]
      cb.call *o
    end 
  end
  
  def emit n, *args
    if (id=messages.indexOf(n.to_s)) >= 0    
      l = java::Org::Jamruby::Ext::ObjectList.create

      pushMsg id,l
      
      args.each do |a|
        if a.is_a?(Integer)
          l.addInt a
        elsif a.is_a?(Float)
          l.addFlt a
        elsif a.is_a?(String)
          l.addStr a
        elsif a.is_a?(JObject)
          l.addObj a
        elsif a.respond_to?(:native)
          l.addObj a.native
        elsif a == true or a == false
          l.addBool a
        elsif a == nil
          l.addNull
        else
          l.addObj a.to_java
        end
      end

      sendEmptyMessage(id)
    end
  end
end 
