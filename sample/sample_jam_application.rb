begin
  java.import "android/widget/Button"

  class Updater
    attr_reader :thread
    def initialize
    
		  @thread = Thread.new do
        begin  
          i = -1        
          
          loop do 
            i+=1
            
            handler.emit(:foo, i)
            
            Thread.jsleep 0.04
          end
        rescue=>e
          p [:THREAD_ERROR, e]
        end
		  end
	  end
	end  

  @b=java::Android::Widget::Button.new(activity)
  @b.setText "Click Me!"  
  @b.setOnClickListener() do
    tst = toast "ouch!"
  end

  activity.setContentView @b
  
  handler.on :foo  do |*o|
    @b.setText "Click Me! -- Thread Looped: #{o[0]} times!"
  end
  
  Updater.new()
rescue => e
  p "MAIN: Error - #{e} :: #{$r}"
end
