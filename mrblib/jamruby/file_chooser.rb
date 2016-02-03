begin  
  java.import "android/widget/ListView"
  java.import "android/widget/TextView"
  java.import "android/widget/LinearLayout"  
  java.import "android/text/TextUtils$TruncateAt"
  
  require "jamruby/array_adapter"  
      
  module JamRuby  
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
rescue => e
  p e
  raise e
end
