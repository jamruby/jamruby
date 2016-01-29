java.import "android/widget/Button"  

class Main < JamRuby::Activity
  def on_create state
    b = Android::Widget::Button.new self
    b.setText "Click Me"
    
    b.setOnClickListener do
      toast "Ouch!"
    end

    setContentView b
  end
end
