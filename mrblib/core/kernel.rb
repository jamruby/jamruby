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
    
    o.length > 1 ? o : o[0]
  end  
  
  def puts *o
    print *o
    o.length > 1 ? o : o[0]
  end
  
  def p *o
    o.each do |q| puts q.inspect end
    o.length > 1 ? o : o[0]
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

REQUIRED_LIBS = {}

class Object
  alias :__jam_require__ :require
  
  # Requires a path
  # If path ends in '.rb' or '.mrb' that file will be loaded
  # Else it will import a Java namespace under ::JAVA
  #
  # @param [String] path
  def require path      
    if File.exist?(path) and !File.directory?(path)
    elsif File.exist?(tmp = path+".rb")
      path = tmp
    elsif File.exist?(tmp = path+".mrb") 
      path = tmp
    elsif $:.is_a?(Array)
      $:.each do |dir|
        if File.exist?(tmp = "#{dir}/#{path}") and !File.directory?(tmp)
          path = tmp
          next
        elsif File.exist?(tmp = "#{dir}/#{path}.rb")
          path = tmp
          next
        elsif File.exist?(tmp = "#{dir}/#{path}.mrb")
          path = tmp
          next
        end                
      end
    end   

    if ["rb", "mrb"].index(q = path.split(".").last)    
    
      path = File.expand_path(path)
    
      if REQUIRED_LIBS[path]
        return false
      end

      REQUIRED_LIBS[path = File.expand_path(path)] = true
    end
    
    if q == "rb"
      __eval__ "JAM_MAIN_HANDLE.loadScriptFull __mrb_context__, '#{path}'"
      return true
    elsif q == "mrb"
      __eval__ "JAM_MAIN_HANDLE.loadCompiledFull __mrb_context__, '#{path}'"
      return true
    else
      __jam_require__ path
    end
  rescue => e
    p e
    raise e
  end
end  
