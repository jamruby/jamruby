begin
  require "java/util/regex/Pattern"
  require "java/util/regex/Matcher"
  require "android/util/Log"
  require "org/jamruby/ext/Util"
  require "org/jamruby/ext/ObjectList"
  
  module List
    def each &b
      this = NWrap.as(self, JAVA::Org::Jamruby::Ext::ObjectList)
      for i in 0..this.size-1
        b.call this.get(i)
      end
    end
  end
  
  def print *o
    o.each do |q| JAVA::Android::Util::Log.i("jam_mrblib.mrb", q.inspect) end
  end  
  
  def puts *o
    print *o
  end
  
  def p *o
    o.each do |q| print q.inspect end
  end
  
  IMPORT_OVERLOADS = {
    "android/widget/Toast" => [
       Proc.new do
         NWrap.static_override JAVA::Android::Widget::Toast, "makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;"
       end
    ],
    
    "android/widget/Button" => [
      Proc.new do
        NWrap.override JAVA::Android::Widget::Button, "setText", "(Ljava/lang/CharSequence;)V"       
      end
    ],
    
    "android/widget/TextView" => [
      Proc.new do
        NWrap.override JAVA::Android::Widget::TextView, "setText", "(Ljava/lang/CharSequence;)V"  
      end
    ]   
  }  
  
  class JWrap  
    # Look up Fields
    def self.const_missing c
      pth = self::WRAP::CLASS_PATH.split("/").join(".")
      cls = JAVA::Org::Jamruby::Ext::Util.classForName(pth )
      if r = JAVA::Org::Jamruby::Ext::FieldHelper.getField(cls, c.to_s)
        return r
      end 
      
      super
    end   
  
    module View
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
  
    def self.set_for t
      self.const_set :WRAP, t
    end
    
    def __to_str__
      c=@dlg.jclass
      m = c.get_method "toString","()Ljava/lang/String;"
      c.call @dlg, m
    end
    
    def inspect
      __to_str__
    end
    
    def to_str
      __to_str__
    end
    
    def initialize obj
      @dlg = obj 
      if respond_to?(:setOnClickListener)
        extend View
      end
    end
    
    def jobj
      q = @dlg
      while q.respond_to?(:jobj)
        q = q.jobj
      end
      
      q
    end
    
    def is_a? what
      if what.is_a?(::String)
        if JAVA::Org::Jamruby::Ext::Util.is_a(self.jobj, what)
          return true
        end
        
        return false
      end
      
      super
    end    
    
    def self.get_signature name, static=false
      sig = (static ? self::WRAP::STATIC_SIGNATURES : self::WRAP::SIGNATURES).find do |s| s[0] == name.to_s end
      if sig
        
        @p ||= NWrap.as(JAVA::Java::Util::Regex::Pattern.compile("\\Q)\\EL(.*?)\;$"), JAVA::Java::Util::Regex::Pattern)
        m = NWrap.as(@p.matcher(sig[1]), JAVA::Java::Util::Regex::Matcher);
        if m.find
          path = m.group[2..-2]
          case path
          when "java/lang/Object"
          when "java/lang/String"
          else
            as = path
          end
        else
          as = nil
        end
        
        m.reset
      end  
      
      return [sig, as]  
    end
    
    def self.m_map
      @_m_map ||= {:static=>{}, :ins=>{}}
    end
    
    def self.add_method name, static = false
      this = self
      
      (static ? singleton_class : self).define_method name do |*o, &b|
        
        sig, as =  this.get_signature(name, static)
        cls = java.import as if as 
      
        o = this.adjust_args *o, &b    
        
        if static
          res = this::WRAP.send name, *o       
        else  
          if @dlg.is_a?(this::WRAP)
            res = @dlg.send name, *o
          else
            c=@dlg.jclass
            m=c.get_method(name, sig[1])
            res = c.call(@dlg, m, *o)
          end
        end
          
        if as
          return cls.wrap(res)
        end
          
        return res
      end
    end
    
    def self.wrap o
      _new(o.respond_to?(:jobj) ? o.jobj : o)
    end
    
    class << self
      alias :_new :new
    end
    
    def self.new *o,&b
      ins = self::WRAP.new *adjust_args(*o,&b)
      wrap ins
    end
    
    def self.adjust_args *o,&b
      args = (o.map do |q|
        q.respond_to?(:jobj) ? q.jobj : q
      end).map do |q|
        if q.is_a? Symbol
          begin
            const_get :"#{q.to_s.upcase}"
          rescue
            q
          end
        else
          q
        end
      end
      
      if b
        args << proxy("java.lang.Runnable", &b)
      end
      
      o    
    end
  end

  class String
    def jmatch str
      p = NWrap.as(JAVA::Java::Util::Regex::Pattern.compile(str), JAVA::Java::Util::Regex::Pattern)
      m = NWrap.as(p.matcher(self), JAVA::Java::Util::Regex::Matcher);
    end
  end

  module JavaBridge
    # Binds Java Class to Ruby
    #
    # @param [String] path the class to import
    # @param [Boolean] bool internal use
    #
    # @return [Class] 
    def self.import path, bool=false
      if path.index("$") and !bool
        # defer to outer class import
        
        import path.split("$")[0]
      end
    
      t = ::JAVA
      a = path.split("/").join(".").split("$").join(".").split(".")
      i = 0
      ot = ::Object
      sym = nil
      
      a.each do |b|
        c=b[0..0].capitalize+b[1..-1]
        if !t.const_defined? c.to_sym
          require path
          if q=IMPORT_OVERLOADS[path]
            q.each do |z|
              z.call
            end
          end
        end
        
        if t.const_defined? c.to_sym
          i += 1
          unless i == a.length
            
            unless ot.const_defined?(c.to_sym)
              ot.const_set(c, nt = Module.new)
            end
          
            ot = ot.const_get(c)
          end
          
          t = t.const_get sym=c.to_sym
        end
      end

      return ot.const_get(:"#{sym}") if ot.const_defined?(:"#{sym}")

      if t!=::Object and i == a.length
        ot.const_set(:"#{sym}", cls=Class.new(JWrap))
        
        cls.set_for t
        
        t::SIGNATURES.each do |o|
          cls.add_method o[0]
        end
        
        t::STATIC_SIGNATURES.each do |o|
          cls.add_method(o[0], true) unless o[0] == "new"
        end
        
        get_inner_classes(path).each do |ic|
          java.import(z=ic.to_s, z.index(path))
        end        
        
        return cls 
      end
    end
    
    # Retrieve a list of inner classes defined in class at +pth+
    #
    # @param [String] pth
    #
    # @return [::Org::Jamruby::Ext::ObjectList] 
    def self.get_inner_classes pth
      o = JAVA::Org::Jamruby::Ext::Util.innerClassesOf(JAVA::Org::Jamruby::Ext::Util.classForName(pth.split("/").join(".")))
      o.extend List
      o
    end
  end

  def java
    JavaBridge
  end    
    
  module NWrap
    def method_missing m,*o
      @classes.reverse.each do |cls|
        if im = cls::SIGNATURES.find do |s| s[0] == m.to_s end
          sig = im[1]
          begin
            if jim = jclass.get_method(m.to_s, sig)
              return jclass.call self, jim, *o
            end
          rescue
          end
        end
      end
      
      super
    end
    
    def self.override cls, m, sig
      if osig = cls::SIGNATURES.find do |s|
        s[0] == m
      end
        osig[1] = sig
      else
        cls::SIGNATURES << [m, sig]
      end
      
      cls.class_eval do
        define_method m do |*o|
          if jim = jclass.get_method(m, sig)
            return jclass.call self, jim, *o
          end
          
          raise "NoMethodError: undefined method #{m} for #{inspect}"
        end
      end
    end
    
    def self.static_override cls, m, sig
      if osig = cls::STATIC_SIGNATURES.find do |s|
        s[0] == m
      end
        osig[1] = sig
      else
        cls::STATIC_SIGNATURES << [m, sig]
      end

      n=cls.define_singleton_method m do |*o|
        if sm = (jclass=JAVA.find_class(cls::CLASS_PATH)).get_static_method(m, sig)
          return jclass.call_static sm, *o
        end
          
        raise "NoMethodError: undefined method #{m} for #{inspect}"
      end
    end    
    
    def as cls
      @classes ||= []
      @classes << cls
      cls
    end
    
    def self.as obj, *cls
      obj.extend self
      cls.each do |c|
        obj.as c
      end
      obj
    end
  end

  java.import "org/jamruby/ext/FieldHelper"
  java.import "android/app/Activity"
  java.import "android/widget/Toast"
  java.import "android/os/Handler"  
  
  java.import "org/jamruby/ext/ObjectList"    
  java.import "org/jamruby/ext/Util"  
  java.import "org/jamruby/ext/Invoke"
  java.import "org/jamruby/ext/UIRunner" 
  java.import "org/jamruby/ext/ProcProxy" 
  java.import "org/jamruby/ext/MessageRunner"
  java.import "org/jamruby/ext/MessageHandler"      
  java.import "org/jamruby/ext/JamActivity"

  java.import "java/lang/Thread"

  class JObject
    def as what
      what.wrap self
    end
  end
 
  class Org::Jamruby::Ext::MessageHandler
    Callbacks = []
    def on n, &b
      id = nil
      if id = registerMessage(n.to_s)
        Callbacks[id] = b
        return true
      end
      
      raise "RegisterMessageError: could not register #{n}"
    end
    
    def dispatch id, *o 
      if id >=0 and cb=Callbacks[id]
        cb.call *o
      end 
    end
    
    def emit n, *args
      if (id=messages.indexOf(n.to_s)) >= 0    
        l = java::Org::Jamruby::Ext::ObjectList.create

        pushMsg id,l
        
        args.each do |a|
          if a.is_a?(Integer)
            l.addInt a
          elsif a.is_a?(Float)
            l.addFlt a
          elsif a.is_a?(String)
            l.addStr a
          elsif a.is_?(JObject)
            l.addObj a
          else
            l.addObj nil
          end
        end

        sendEmptyMessage(id)
      end
    end
  end 

  class Thread
    def self.jsleep i
      i = i * 1000.0
      Java::Lang::Thread.sleep i.to_i
    end
  end

  module Kernel        
    def toast str, len = 500
      tst = Android::Widget::Toast.makeText activity, str, len
      tst.show
      tst
    end
    
    def print *o
      o.each do |q| JAVA::Android::Util::Log.i("jam_mrblib.mrb", q.inspect) end
    end  
    
    def puts *o
      print *o
    end
    
    def p *o
      o.each do |q| print q.inspect end
    end

    def activity
      Org::Jamruby::Ext::JamActivity.getInstance
    end

    def handler
      activity.getHandler
    end
    
    def sleep amt
      Thread.jsleep amt
    end
  end
rescue => e
  $r=e
  p $r
end
