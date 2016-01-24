begin
  java.import "android/widget/TextView"
  java.import "android/widget/Button"
  java.import "android/widget/LinearLayout"
  java.import "android/widget/ProgressBar"  
  java.import "android/widget/EditText"  
  java.import "android/widget/ScrollView" 

  ll = Android::Widget::LinearLayout.new(activity)
  
  src = Android::Widget::EditText.new(activity)
  b   = Android::Widget::Button.new(activity)
  
  src.setText "http://download.linnrecords.com/test/flac/recit24bit.aspx"
  b.setText   "Download"
  
  src.setMaxLines 1 
  src.setHorizontallyScrolling(true);

  sv  = Android::Widget::ScrollView.new(activity)
  ll2 = Android::Widget::LinearLayout.new(activity)
  ll2.setOrientation :vertical
  sv.addView ll2
  
  ll.addView src, param = Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.1);
  ll.addView b, param
  ll.addView sv,  Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 1.0);
  
  ll.setOrientation :vertical

  @items = {}
  
  def init id, uri, size, destination
    @items[id][:uri]         = uri
    @items[id][:size]        = size
    @items[id][:destination] = destination
  end  
  
  def update id, pct
    pct = 1.0 if pct.infinite?
    
    d = @items[id]

    d[:progress].setProgress (pct*100.0).to_i
    
    if d[:size] < 1024
      units = "b"
      s = d[:size]
      t = d[:size] * pct
    elsif d[:size] < 1024 * 1024
      units = "K"
      s = d[:size] / 1024.0
      t = (d[:size] * pct) / 1024.0
    else
      units = "M"
      s = d[:size] / 1024 / 1024.0
      t = (d[:size] * pct) / 1024 / 1024.0      
    end
    
    d[:label].setText "#{d[:uri]}\nSave to: #{d[:destination]}\n"+
                      "#{sprintf("%.2f", pct*100.0)}% "+
                      "#{sprintf("%.2f%s", t, units)} / "+
                      "#{sprintf("%.2f%s", s, units)}"
  end  
  
  def finish id, status, code
    d = @items[id]
    d[:label].setText("#{m = status == PBR::Download::COMPLETE ? "Completed" : "Error: #{code}"}: "+d[:uri])
    toast "Download: #{id} - #{m}", 1000
  end
    
  b.setOnClickListener do 
    pb = Android::Widget::ProgressBar.new(activity, nil, Android::R::Attr::ProgressBarStyleHorizontal);
    tv = Android::Widget::TextView.new(activity)
    
    ll2.addView pb, param
    ll2.addView tv, param
    
    @items[id = @items.length] = {
      :progress => pb,
      :label    => tv
    }
    
    Thread.new(id, src.getText.to_s) do |id, uri|
      begin        
        begin
          d = PBR::Download.new uri, :dest_dir => "/sdcard/Download", :dest_filename => PBR::Download.unique_filename(uri, :dest_dir => "/sdcard/Download") do
            main :finish, id, d.status, d.code
          end
   
          main :init, id, d.uri, d.size, d.destination   
   
          d.on_progress do
            main :update, id, d.percent
          end 
          
          d.start
        rescue PBR::Download::RequestError => e
          main :init, id, uri  , 0, ""      
          main :finish, id, PBR::Download::EMPTY , e.code
        end
      rescue => e
        main :init, id, uri, 0, ""
        main :finish, id, PBR::Download::ERROR, -1
        p e
      end
    end
  end

  activity.setContentView(ll)
rescue => e
  puts "MAIN: Error: #{e.inspect} :: #{$r.inspect}"
end
