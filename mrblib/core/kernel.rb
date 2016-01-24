require "java/lang/Thread"
module JamRuby
  class Message
    def initialize target = nil, java_method = "rubySendMain"
      @java_method = java_method
      @target = target
    end
    
    def method_missing m, *o
      if @target
        JAVA::Org::Jamruby::Ext::Util.send @java_method, @target.to_s, m.to_s, o.to_object_list.native
      else
        JAVA::Org::Jamruby::Ext::Util.send @java_method, m.to_s, o.to_object_list.native
      end
    end 
    
    def block
      self.class.new(@target, @java_method + "Block")
    end
    
    class MainMessage < Message
      def activity
        Message.new(nil, "rubySend")
      end
    end
  end
end

module Kernel          
  def print *o
    o.each do |q| JAVA::Android::Util::Log.i("jamruby", q.to_s) end
  end  
  
  def puts *o
    print *o
  end
  
  def p *o
    o.each do |q| puts q.inspect end
  end
  
  def sleep i
    i = i * 1000.0
    JAVA::Java::Lang::Thread.sleep i.to_i
  end
  
  def java
    JamRuby::Bridge
  end   
  
  def main(_self_ = nil)
    JamRuby::Message::MainMessage.new(_self_, _self_ ? "rubySendWithSelfFromReturn" : "rubySendMain")
  end
end
  
