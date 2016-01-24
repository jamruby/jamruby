begin
  java.import "android/widget/Button"
  java.import "android/widget/LinearLayout"
  java.import "android/widget/ProgressBar"  
  java.import "android/widget/ScrollView" 

  ll = Android::Widget::LinearLayout.new(activity)
  
  b  = Android::Widget::Button.new(activity)
  b.setText "Add Task"

  sv  = Android::Widget::ScrollView.new(activity)
  ll2 = Android::Widget::LinearLayout.new(activity)
  ll2.setOrientation :vertical
  sv.addView ll2
  
  ll.addView b,  param = Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.1);
  ll.addView sv, Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 1.0);
  
  ll.setOrientation :vertical

  @items = []
    
  def update id, pct
    @items[id].setProgress pct
  end  
    
  b.setOnClickListener do 
    pb = Android::Widget::ProgressBar.new(activity, nil, Android::R::Attr::ProgressBarStyleHorizontal);

    ll2.addView pb, param
    
    @items << pb
    
    id = @items.length-1
    
    Thread.new(id) do |id|
      begin
        i = -1
        while i < 100
          i += 1
          main :update, id, i
          sleep 0.05
        end
        main :toast, "Complete", 1000
      rescue => e
        p e
      end
    end
  end

  activity.setContentView(ll)
rescue => e
  puts "MAIN: Error: #{e.inspect} :: #{$r.inspect}"
end
