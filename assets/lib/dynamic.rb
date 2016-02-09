java.import "android/widget/TextView"
  
class Main < JamRuby::Activity
  def on_create state
    tv = Android::Widget::TextView.new self
    tv.setText "Oh... You can see me?\nWierd..."
    
    setContentView tv
  end
end

