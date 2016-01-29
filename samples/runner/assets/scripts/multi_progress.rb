java.import "android/widget/Button"
java.import "android/widget/LinearLayout"
java.import "android/widget/ProgressBar"  
java.import "android/widget/ScrollView" 

class Main < JamRuby::Activity
  def update id, pct
    @items[id].setProgress pct
  end    

  def on_create state
    ll = Android::Widget::LinearLayout.new(self)
    
    b  = Android::Widget::Button.new(self)
    b.setText "Add Task"

    sv  = Android::Widget::ScrollView.new(self)
    ll2 = Android::Widget::LinearLayout.new(self)
    ll2.setOrientation :vertical
    sv.addView ll2
    
    ll.addView b,  param = Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.1);
    ll.addView sv, Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 1.0);
    
    ll.setOrientation :vertical

    @items = []
      
    b.setOnClickListener do 
      pb = Android::Widget::ProgressBar.new(self, nil, Android::R::Attr::ProgressBarStyleHorizontal);
     # 100.times do
      ll2.addView pb, param
      
      @items << pb
      
      id = @items.length-1
      
      Thread.new(id) do |id|
        i = -1

        while i < 100
          i += 1
        
          main.activity.update id, i
        
          sleep 0.05
        end
        
        main.toast "Complete #{id}"
      end   
    end

    setContentView(ll)
  end
end
