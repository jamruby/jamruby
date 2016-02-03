java.import "org/jamruby/ext/ObjectList"    
java.import "org/jamruby/ext/Parameter"
java.import "org/jamruby/ext/Util"  
java.import "org/jamruby/ext/JamThread"

module JamRuby
  module ExposedMethods
    def send_with_casted_params mname, *o
      o = o.map do |q|
        if q.is_a?(JObject)
          if JamRuby::NativeObject.wrap(q).is_a?("org.jamruby.ext.Parameter")
            param = Org::Jamruby::Ext::Parameter.wrap(q)
            if !param.isNull
              begin
                next param.object.cast(param.name.split(".").join("/"))
              rescue
                next q
              end
            end
          end
        end
        
        next q
      end

      send mname, *o
    rescue => e
      p e
      raise e
    end
  end
end


def JAM_MAIN_HANDLE.loadScriptFull mrb, path
  im = jclass.get_method "loadScriptFull", "(JLjava/lang/String;)Lorg/jamruby/mruby/Value;"
  jclass.call self, im, mrb, path
end

def JAM_MAIN_HANDLE.loadCompiledFull mrb, path
  im = jclass.get_method "loadCompiledFull", "(JLjava/lang/String;)Lorg/jamruby/mruby/Value;"
  jclass.call self, im, mrb, path
end

class Org::Jamruby::Ext::ObjectList
  def self.wrap o
    r = super o
    r.extend JamRuby::NativeList
    r
  end
end

class Thread
  def initialize *o, &b
    @jam_thread = Org::Jamruby::Ext::JamThread.new(JAM_MAIN_HANDLE, o.to_object_list, b.to_java).native
    @jam_thread.start
  end
  
  def native
    jam_thread.native
  end
  
  def jam_thread
    @jam_thread
  end
  
  def join
    jam_thread.join
  end
end

