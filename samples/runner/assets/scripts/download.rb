java.import "android/widget/TextView"
java.import "android/widget/Button"
java.import "android/widget/LinearLayout"
java.import "android/widget/ProgressBar"  
java.import "android/widget/EditText"  
java.import "android/widget/ScrollView" 

class Main < JamRuby::Activity
  def dl_init id, uri, size, destination
    @items[id][:uri]         = uri
    @items[id][:size]        = size
    @items[id][:destination] = destination
    @items[id][:pct]         = 0.0
    @items[id][:complete]    = false
  end  
  
  
  def update
    
    @items.map do |id, d|
      next if d[:complete]
      
      d[:pct] = @ol.to_a[id]
      d[:progress].setProgress (d[:pct]*100.0).to_i
      
      if d[:size] < 1024
        units = "b"
        s = d[:size]
        t = d[:size] * d[:pct]
      elsif d[:size] < 1024 * 1024
        units = "K"
        s = d[:size] / 1024.0
        t = (d[:size] * d[:pct]) / 1024.0
      else
        units = "M"
        s = d[:size] / 1024 / 1024.0
        t = (d[:size] * d[:pct]) / 1024 / 1024.0      
      end
      
      d[:label].setText "#{d[:uri]}\nSave to: #{d[:destination]}\n"+
                        "#{sprintf("%.2f", d[:pct]*100.0)}% "+
                        "#{sprintf("%.2f%s", t, units)} / "+
                        "#{sprintf("%.2f%s", s, units)}"
    end
  rescue => e
    p e
  end  
  
  def poll
    @ol = Org::Jamruby::Ext::ObjectList.create
    Thread.new do
      begin
      loop do
        main.block.activity.update
        sleep 0.3
      end
      rescue => e
        p e
      end
    end
  rescue => e
    p e
  end
  
  def dl_finish id, status, code
    d = @items[id]
    d[:complete] = true
    d[:progress].setProgress 100
    d[:label].setText("#{m = status == PBR::Download::COMPLETE ? "Completed" : "Error: #{code}"}: "+d[:uri])
    toast "Download: #{id} - #{m}"
  end    
  
  def on_create state
    ll = Android::Widget::LinearLayout.new(self)
    
    src = Android::Widget::EditText.new(self)
    b   = Android::Widget::Button.new(self)
    
    src.setText "http://download.linnrecords.com/test/flac/recit24bit.aspx"
    b.setText   "Download"
    
    src.setMaxLines 1 
    src.setHorizontallyScrolling(true);

    sv  = Android::Widget::ScrollView.new(self)
    ll2 = Android::Widget::LinearLayout.new(self)
    ll2.setOrientation :vertical
    sv.addView ll2
    
    ll.addView src, param = Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.1);
    ll.addView b, param
    ll.addView sv,  Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 1.0);
    
    ll.setOrientation :vertical

    @items = {}
      
    b.setOnClickListener do 
      pb = Android::Widget::ProgressBar.new(self, nil, Android::R::Attr::ProgressBarStyleHorizontal);
      tv = Android::Widget::TextView.new(self)
      
      ll2.addView pb, param
      ll2.addView tv, param
      
      @items[id = @items.length] = {
        :progress => pb,
        :label    => tv
      }
      
      @ol.addFlt 0.0
      
      Thread.new(id, src.getText.to_s, @ol) do |id, uri, ol|
        ol = Org::Jamruby::Ext::ObjectList.wrap ol
        begin        
          begin
            d = PBR::Download.new uri, :dest_dir => "/sdcard/Download", :dest_filename => PBR::Download.unique_filename(uri, :dest_dir => "/sdcard/Download") do
              main.activity.dl_finish id, d.status, d.code
            end
     
            main.activity.dl_init id, d.uri, d.size, d.destination   
     
            d.on_progress do
              ol.setFlt(id, d.percent)
            end 
            
            d.start
          rescue PBR::Download::RequestError => e
            main.activity.dl_init id, uri  , 0, ""      
            main.activity.dl_finish id, PBR::Download::EMPTY , e.code
          end
        rescue => e
          main.activity.dl_init id, uri, 0, ""
          main.activity.dl_finish id, PBR::Download::ERROR, -1
          p e
        end
      end
    end

    setContentView(ll)
    poll
  end
end
