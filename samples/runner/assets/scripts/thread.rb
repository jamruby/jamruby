java.import "android/widget/TextView"
java.import "android/widget/Button"
java.import "android/widget/LinearLayout"

class Updater
  attr_reader :thread
  def initialize
    @thread = Thread.new do
      i = -1       
      
      java.import "java/lang/Thread"
      
      loop do 
        main.activity.update i+=1
        
        sleep 0.04
      end
    end
  end
end  

class Main < JamRuby::Activity
  def update i
    @tv.setText "Thread: looped #{i} times."
  end
  
  def on_create state
    param = Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 3.0);
    
    ll = Android::Widget::LinearLayout.new(self)
    ll.setOrientation :vertical
    
    @tv = tv = Android::Widget::TextView.new(self)
    
    b=Android::Widget::Button.new(self)
    b.setText "Click Me!"  
    b.setOnClickListener() do |v|
      toast "ouch!"
    end

    ll.addView(tv, param)
    ll.addView(b)
    
    setContentView ll
    
    Updater.new()
  end
end
