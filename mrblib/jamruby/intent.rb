begin
  java.import "android/content/Intent"
  java.import "org/jamruby/ext/JamIntent"

  module JamRuby
    class Intent < Android::Content::Intent
      def putExtra key, val
        jc = native.jclass

        paths = ["Ljava/lang/String;"]
        
        if val.is_a?(String)
          paths[1] = paths[0]
        elsif val.is_a? Integer
          paths[1] = "I"
        elsif val.is_a? Float
          paths[1] = "F"
        else
          raise ArgumentError.new("bad value")                   
        end

        im = jc.get_method("putExtra", "(#{paths.join()})Landroid/content/Intent;")
        jc.call native, im, key, val
      end 
      
      def self.createComponent *o
        ins = wrap Org::Jamruby::Ext::JamIntent.createComponent(*o).native
      end
      
      def self.new *o
        _new *o
      end
    end
  end
rescue => e
  p e
  raise e
end
