begin  
  java.import "org/jamruby/ext/JavascriptObject"    
  module JamRuby
    class JavascriptInterface < Org::Jamruby::Ext::JavascriptObject          
      def initialize *argv, &proc
        @native = Org::Jamruby::Ext::JavascriptObject.new JAM_MAIN_HANDLE, argv, proc.to_java
      end
      
      def self.new *argv, &proc
        _new(*argv, &proc)
      end
    end
  end
rescue => e
  p e
  raise e
end
