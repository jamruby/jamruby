begin
  java.import("android/widget/TextView")
  java.import "android/widget/Button"
  java.import "android/widget/LinearLayout"

  class Updater
    attr_reader :thread
    def initialize
      @thread = Thread.new do
        begin  
          i = -1       

          loop do 
            handler.emit :foo, i+=1
            sleep 0.04
          end
        rescue=>e
          p [:THREAD_ERROR, e]
        end
      end
    end
  end  
  
  param = java::Android::Widget::LinearLayout::LayoutParams.new(-1, -2, 3.0);
  
  ll = java::Android::Widget::LinearLayout.new(activity)
  ll.setOrientation java::Android::Widget::LinearLayout::VERTICAL
  
  tv = java::Android::Widget::TextView.new(activity)
  
  b=java::Android::Widget::Button.new(activity)
  b.setText "Click Me!"  
  b.setOnClickListener() do
    tst = toast "ouch!"
  end

  ll.addView(tv, param)
  ll.addView(b)
  
  activity.setContentView ll
  
  handler.on :foo  do |*o|
    tv.setText "Thread Looped: #{o[0]} times!"
  end
  
  Updater.new()
rescue => e
  p "MAIN: Error - #{e} :: #{$r}"
end
