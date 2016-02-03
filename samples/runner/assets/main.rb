java.import "org/jamruby/runner/SpawnedActivity"
java.import "org/jamruby/runner/SpawnedCompiledActivity"  
java.import "android/webkit/WebView"
java.import "android/widget/ViewSwitcher"
java.import "android/widget/Button"

require "jamruby/file_chooser"
require "jamruby/javascript_interface"

class Main < JamRuby::Activity
  def is_compiled? path
    File.basename(path).split(".").last == "mrb" 
  end
  
  def is_source? path
    File.basename(path).split(".").last == "rb" 
  end
 
  def on_create s
    @ready = false
    @_mode = :run 
  
    @vs = Android::Widget::ViewSwitcher.new(self)
    
    @vs.addView ll1 = Android::Widget::LinearLayout.new(self)
    ll1.setOrientation :vertical
    
    @fc = JamRuby::FileChooserView.new(self, getScriptsDir, :header => "Select an Activity file", :type => ["mrb", "rb"])
    @fc.on_select do |path|
      if @_mode == :run
        on_run path
      else  
        @edit = path
        @wv.loadUrl("file:///android_asset/www/edit.html")
        @vs.showNext()
      end
    end
    
    ll1.addView mode = Android::Widget::Button.new(self), Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.1)    
    mode.setText "Run Mode"
    mode.setOnClickListener do
      if @_mode == :run
        @_mode = :edit
        @fc.update({:type => "rb"})
        mode.setText "Edit Mode"
      else  
        @_mode = :run
        @fc.update({:type => ["mrb", "rb"]})
        mode.setText "Run Mode"        
      end
    end
    
    ll1.addView @fc, Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 1.0)
    
    ll2 = Android::Widget::LinearLayout.new(self)
    ll2.setOrientation :vertical
    
    @vs.addView ll2
    
    ll2.addView toolbar=Android::Widget::LinearLayout.new(self), Android::Widget::LinearLayout::LayoutParams.new(:fill_parent, :wrap_content, 0)
    ll2.addView @wv=Android::Webkit::WebView.new(self), Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :match_parent, 1.0)
    
    toolbar.addView undo  = Android::Widget::Button.new(self), Android::Widget::LinearLayout::LayoutParams.new(:wrap_content, :wrap_content, 0.1)
    toolbar.addView re_do = Android::Widget::Button.new(self), Android::Widget::LinearLayout::LayoutParams.new(:wrap_content, :wrap_content, 0.1)
    toolbar.addView run   = Android::Widget::Button.new(self), Android::Widget::LinearLayout::LayoutParams.new(:wrap_content, :wrap_content, 1.0)
    toolbar.addView save  = Android::Widget::Button.new(self), Android::Widget::LinearLayout::LayoutParams.new(:wrap_content, :wrap_content, 0.1)            
    
    undo.setText "Undo"
    re_do.setText "Redo"
    run.setText "Run"
    save.setText "Save" 
    
    undo.setOnClickListener do
      @wv.loadUrl("javascript:undo();")
    end
    
    re_do.setOnClickListener do
      @wv.loadUrl("javascript:redo();")
    end    
    
    run.setOnClickListener do
      if @ready
        @wv.loadUrl("javascript:save('#{@edit}');run();")
      else
        on_run
      end
    end 
    
    save.setOnClickListener do
      @wv.loadUrl("javascript:save('#{@edit}');") if @ready
    end              
    
    @wv.getSettings().setJavaScriptEnabled(true);
    @wv.addJavascriptInterface((JamRuby::JavascriptInterface.new() do
      def read_file path
        File.read(path)
      end
      
      def write json
        path, buff = JSON.load(json)
        File.open(path, "w") do |f| f.puts buff end
      end
      
      def on_ready
        main.activity.on_load()
      end
      
      def run
        main.activity.on_run
      end
    end), "ruby");   
    
    setContentView @vs
  end
  
  def on_load
    @wv.loadUrl("javascript:loadFile('#{@edit}');")
    @ready = true
  end
  
  def on_run path=@edit
    activity_type = is_compiled?(path) ? Org::Jamruby::Runner::SpawnedCompiledActivity : Org::Jamruby::Runner::SpawnedActivity
    
    intent = JamRuby::Intent.createComponent(getBaseContext, activity_type)
    intent.putExtra("org.jamruby.ext.dynamic.MAIN", path)

    startActivity intent   
  end
  
  def on_back_pressed
    if @edit
      @vs.showPrevious 
      @edit = nil
      @ready = false
      
      return false
    end
    
    super
  end
end

