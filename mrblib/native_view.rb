module JamRuby
  module NativeView
    # Wraps a Android.View.View
    # methods caled will be ran on UiThread
    class UI
      def initialize ins
        @pth = ins.class::WRAP::CLASS_PATH
        @cls = ins.class::WRAP
        @ins = ins
        @posts = {}
      end
    
      def method_missing m, *o
        if !@posts[m] and @ins.respond_to?(m)
          pth = @pth.split("/").join(".")
         
          ui = Org::Jamruby::Ext::UIRunner.new(pth, @ins, m.to_s)
          
          if sig=@cls::SIGNATURES.find do |s| s[0] == m.to_s end
            args = sig[1].split(")")[0][1..-1]
            if args.index("[")
              raise "NotSupportedError: cannot create array params."
            end
            
            types = []

            mtch = args.jmatch("[I]|[J]|[Z]|L(.*?)\;")
            while mtch.find
              q = mtch.group
              if q[0..0] == "L"
                types << q[1..-2].split("/").join(".")
              elsif q == "I"
                types << "java.lang.Integer"
              end
            end
            
            types.each do |t|
              ui.atypes.addStr t
            end
          
            @posts[m] = [ui, types]
          end  
        end
        
        if @posts[m]
          if o.length != @posts[m][1].length
            raise "ArgumentError: #{o.length} for #{@posts[m][1].length}"
          end
          
          ui = @posts[m][0] 
          
          ui.args.clear
          ui.args.trimToSize
          
          o.each_with_index do |a, i|
            case @posts[m][1][i]
            when "java.lang.Object"
              ui.args.addObj a
            when "java.lang.String"
              ui.args.addStr a   
            when "java.lang.Integer"
              ui.args.addInt a                                 
            when "java.lang.Double"
              ui.args.addDbl a                                 
            when "java.lang.Float"
              ui.args.addFlt a   
            else
              ui.args.addObj a
            end
          end
          
          @ins.post @posts[m][0]
          
          return true
        end
        
        super
      end
    end
  
    def setOnClickListener &b
      @cb = b
      super(proxy("android.view.View$OnClickListener", &@cb))
    end
    
    # @return [UI] wrapper of self whose methods are thread safe
    def ui
      @ui ||= UI.new(self)
    end
  end
end
