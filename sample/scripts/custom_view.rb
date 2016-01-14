begin
  java.import("android/widget/TextView")
  java.import "android/widget/Button"
  java.import "android/widget/LinearLayout"
  java.import "android/graphics/Paint"  
  java.import "android/graphics/Color"  
  java.import "android/graphics/RectF"   
  java.import "android/graphics/Canvas"       
  java.import "org/jamruby/ext/JamView"
  class CustomView < Org::Jamruby::Ext::JamView
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
  end

  class CircleView < CustomView
    def initialize context, fill=:blue, stroke=:red, pct=0.25
      super context
      @fill = Android::Graphics::Color.const_get(:"#{fill.to_s.upcase}")
      @stroke = Android::Graphics::Color.const_get(:"#{stroke.to_s.upcase}")
      
      # radius will be: (shortest dimension / 2) * pct
      @pct = pct
    end
  
    def on_draw canvas
      canvas = Android::Graphics::Canvas.wrap canvas
      draw_fill canvas
      draw_stroke canvas
    end
    
    def draw_fill canvas
			pt = Android::Graphics::Paint.new();
			pt.setAntiAlias(true);
			pt.setColor(@fill);
      e = Org::Jamruby::Ext::Util.enums(Org::Jamruby::Ext::Util.classForName("android.graphics.Paint$Style"))
			pt.setStyle(e.get(2)); 
      
      # draw centered circle 
			canvas.drawOval(Android::Graphics::RectF.new(*get_virtual_rect), pt)     
    end
    
    def draw_stroke canvas
      pt = Android::Graphics::Paint.new();
			pt.setAntiAlias(true);
			pt.setColor(@stroke);
      e = Org::Jamruby::Ext::Util.enums(Org::Jamruby::Ext::Util.classForName("android.graphics.Paint$Style"))
			pt.setStyle(e.get(1)); 
			pt.setStrokeWidth(4.5);
      
      # draw centered circle 
			canvas.drawOval(Android::Graphics::RectF.new(*get_virtual_rect), pt)      
    end
    
    def get_virtual_rect
      w = getWidth
      h = getHeight
      
      # only use the shortest dimension
      max_d = w > h ? h : w
      
      # define radius
      r = (max_d / 2.0) * @pct
     
      # virtual coordinates
      vx1 = (max_d - r*2) / 2
      vx2 = (vx1 + r*2)
      
      # translate coords to rect
      x1 = vx1 + dif_x=(w - max_d)/2
      x2 = vx2 + dif_x
      y1 = vx1 + dif_y=(h - max_d)/2
      y2 = vx2 + dif_y      
      
      return x1,y1,x2,y2
    end
  end
  

  cv = CircleView.new(activity, :blue, :white, 0.33)
  
  activity.setContentView cv
rescue => e
  p "MAIN: Error - #{e} :: #{$r}"
end
