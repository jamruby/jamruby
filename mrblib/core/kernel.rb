__eval__ "require 'java/lang/Thread';"+
         "require 'org/jamruby/ext/InvokeResult'"

module JamRuby
  class Message
    def initialize target = nil, java_method = "rubySendMain"
      @java_method = java_method
      @target = target
    end
    
    def method_missing m, *o
      h = JAM_MAIN_HANDLE.respond_to?(:native) ? JAM_MAIN_HANDLE.native : JAM_MAIN_HANDLE
    
      if @target
        JAVA::Org::Jamruby::Ext::Util.send @java_method, h, @target.to_s, m.to_s, o.to_object_list.native
      else
        JAVA::Org::Jamruby::Ext::Util.send @java_method, h, m.to_s, o.to_object_list.native
      end
    end 
    
    def block
      self.class.new(@target, @java_method + "Block")
    end
    
    class MainMessage < Message
      def activity
        Message.new(:activity, "rubySendMainWithSelfFromResult")
      end
    end
  end
end

class Exception
  class Wrapper
    def initialize error
      @error = error
    end
    
    def get_error
      @error
    end
  end
  
  def to_java
    ins = Wrapper.new self
    JAVA::Org::Jamruby::Ext::RubyObject.create(JAM_THREAD_STATE, _to_java_(ins))
  end
end

module Kernel          
  def print *o
  
    o.each do |q| 
      JAVA::Android::Util::Log.i("jamruby", q.to_s)
    end
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
    JamRuby::Message::MainMessage.new(_self_, _self_ ? "rubySendMainWithSelfFromResult" : "rubySendMain")
  end
  
  def to_java
    JAVA::Org::Jamruby::Ext::RubyObject.create(JAM_THREAD_STATE, _to_java_(self))
  end  
  
  def send_with_result mname, result, *o
    return send(mname, *o)
  rescue => e
    result = JamRuby::NativeWrapper.as result, JAVA::Org::Jamruby::Ext::InvokeResult
    
    result.setError true
    result.setErrorObject e.to_java
    result.setErrorMessage "#{mname}: #{e}"
    result.setErrorDetail e.inspect
    result.setErrorBacktrace(e.backtrace.to_object_list.native)
  
    return nil
  end
end

class Object
  alias :__jam_require__ :require
  
  # Requires a path
  # If path ends in '.rb' or '.mrb' that file will be loaded
  # Else it will import a Java namespace under ::JAVA
  #
  # @param [String] path
  def require path
    q = path.split(".").last
    if q == "rb"
      JAM_MAIN_HANDLE.loadScriptFull __mrb_context__, path
    elsif q == "mrb"
      JAM_MAIN_HANDLE.loadCompiledFull __mrb_context__, path
    else
      __jam_require__ path
    end
  end
end
  
