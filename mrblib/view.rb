java.import "android/graphics/Canvas"       
java.import "org/jamruby/ext/JamView"

module JamRuby
  class View < Org::Jamruby::Ext::JamView
    def initialize context
      @dlg = Org::Jamruby::Ext::JamView.new(context, to_java(self)).jobj
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
