begin
  java.import "android/widget/Toast"
  java.import "android/R"
  java.import "org/jamruby/ext/JamActivity"
  java.import "android/content/Intent"
  java.import "org/jamruby/ext/JamIntent"
  java.import "org/jamruby/ext/JavascriptObject"
  java.import "android/widget/ListView"
  java.import "android/widget/TextView"
  java.import "android/widget/LinearLayout"  
  java.import "android/text/TextUtils$TruncateAt"  
    
  module JamRuby
    class JavascriptInterface < Org::Jamruby::Ext::JavascriptObject
      def initialize *argv, &proc
        @native = Org::Jamruby::Ext::JavascriptObject.new JAM_MAIN_HANDLE, argv, proc.to_java
      end
      
      def self.new *argv, &proc
        _new(*argv, &proc)
      end
    end
  
    class FileChooserView < Android::Widget::LinearLayout
      def initialize ctx, path = "./", *argv                
        @lv = Android::Widget::ListView.new(ctx)
        
        @native = Android::Widget::LinearLayout.new(ctx).native
        
        @lv.setOnItemClickListener do |lv, v, pos, id|
          base = @files[pos]
          
          path = @path+"/"+base 
          
          if File.directory?(path)
            @path = trim_path(path)
            @location.setText @path
            @lv.setAdapter JamRuby::ArrayAdapter.new(ctx, @files = list(path))
            @lv.postInvalidate
          else
            @selection = path
            @selected_cb.call(path) if @selected_cb
          end
        end
        
        @opts = {
          :path=>path,
          :header=>"Choose a file.",
          :type=>nil
        }
      
        @ctx  = ctx
        
        setOrientation :vertical
        
        addView @tv = Android::Widget::TextView.new(ctx), Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.0)
        addView @location = Android::Widget::TextView.new(ctx), Android::Widget::LinearLayout::LayoutParams.new(:match_parent, :wrap_content, 0.0)
        addView @lv, Android::Widget::LinearLayout::LayoutParams.new(:match_parent, 0, 1.0)
        
        @location.setSingleLine true
        @location.setEllipsize Android::Text::TextUtils::TruncateAt::END
        
        update argv[0]
      end
      
      def trim_path path
        path = File.expand_path(path)
        a = path.split("..")
        n = a.reverse
        while n.shift == ".."
          a.pop
        end
        path = a.join("..")
      end
      
      def update opts        
        if opts.is_a?(Hash)
          opts.map do |k, v|
            @opts[k] = v
          end
        end
      
        @path      = trim_path(@opts[:path])
        @header    = @opts[:header]
        @type      = @opts[:type]
        @selection = nil
        
        @lv.setAdapter JamRuby::ArrayAdapter.new(@ctx, @files = list(@path))        
        @lv.postInvalidate
        
        @tv.setText @header
        
        @location.setText @path      
      end
      
      def list path
        Dir.entries(path).find_all do |f|
          next true if [".", ".."].index(f)
          
          next true if File.directory?(path+"/"+f)
        
          if @type
            if @type.is_a?(Array)
              next @type.index(f.split(".").last)
            end
            
            next f.split(".").last == @type
          end
          
          next true
        end      
      end
      
      def on_select &b
        @selected_cb = b
      end
      
      def path
        @path
      end
      
      def selection
        @selection
      end

      def self.new ctx, path="./", *argv
        _new ctx, path, *argv
      end
    end  
  end
   
  module JamRuby
    class Intent < Android::Content::Intent
      def putExtra key, val
        jc = native.jclass

        paths = ["Ljava/lang/String;"]
        
        if val.is_a?(String)
          paths[1] = paths[0]
        elsif val.is_a? Integer
          paths[1] = "I"
        elsif val.is_a? Float
          paths[1] = "F"
        else
          raise ArgumentError.new("bad value")                   
        end

        im = jc.get_method("putExtra", "(#{paths.join()})Landroid/content/Intent;")
        jc.call native, im, key, val
      end 
      
      def self.createComponent *o
        ins = wrap Org::Jamruby::Ext::JamIntent.createComponent(*o).native
      end
      
      def self.new *o
        _new *o
      end
    end
  end

  module JamRuby
    module NativeActivity
      def init act
        path = act.getClass.getName.split(".").join("/")
        cls = java.import(path) 
        @native = act.native
        m = Module.new
        
        m.module_eval do
          cls::WRAP::SIGNATURES.each do |s|
            unless act.respond_to?(:"#{s[0]}")
              define_method s[0] do |*o|
                cls.wrap(native).send s[0], *o
              end
            end
          end
        end
        
        extend m
      end
    end
  
    class Activity < Org::Jamruby::Ext::JamActivity
      include NativeActivity
      def initialize
        init Org::Jamruby::Ext::JamActivity.wrap(JAM_ACTIVITY)
      end
      
      def self.new
        _new()
      end
      
      def on_pause
        # ...
      end
      
      def on_resume
        # ...
      end
      
      def on_stop
        # ...
      end
      
      def on_start
        # ...
      end
      
      def on_restart
        # ...
      end
      
      # @return [true] to not kill process
      def on_destroy
        false
      end
      
      # Called when the Activity is created.  
      # Typically the main entry point
      #
      # @param [Bundle] state
      def on_create state
        # ...
      end
      
      def on_back_pressed
        true
      end
    end
  end
 
  module Kernel
    # Toasts a message
    #
    # @param [String] str
    def toast str
      tst = Android::Widget::Toast.makeText activity, str, 1000
      tst.show
      tst
    end

    # Gets the Activity
    #
    # @return [JamRuby::Activity]
    def activity
      ACTIVITY
    end
  end 

rescue => e
  JAVA::Android::Util::Log.e("activity.mrb", "Error: #{e}")
  $r = e
end
