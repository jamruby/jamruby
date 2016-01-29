begin 
  java.import "android/widget/ArrayAdapter"
  java.import "org/jamruby/ext/JamAdapter"    
  java.import "org/jamruby/ext/JamView"
  
  module JamRuby
    class ArrayAdapter < Android::Widget::ArrayAdapter
      def initialize context, items
        @native = Org::Jamruby::Ext::JamAdapter.create(context, items).toArrayAdapter.native
      end

      def self.new context, items
        _new(context, items)
      end
    end

    class View < Org::Jamruby::Ext::JamView
      def initialize context
        @native = Org::Jamruby::Ext::JamView.new(context, to_java).native
        extend JamRuby::NativeView
      end
      
      def on_draw canvas
        # void
      end

      def on_measure w,h
        setMeasuredDimension w,h
      end
      
      def self.new context,*o
        _new(context, *o)
      end
      
      def on_touch_event e
        # void
      end
    end
  end
rescue => e
JAVA::Android::Util::Log.e("activity.mrb", e.inspect)
  $r = e
end
