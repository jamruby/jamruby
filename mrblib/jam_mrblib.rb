begin
  require "java/util/regex/Pattern"
  require "java/util/regex/Matcher"
  require "android/util/Log"
  require "org/jamruby/ext/Util"
  
  def p *o
    o.each do |q| Android::Util::Log.i("jam_mrblib.mrb", q.inspect) end
  end  
  
  IMPORT_OVERLOADS = {
    "android/widget/Toast" => [
       Proc.new do
         NWrap.static_override Android::Widget::Toast, "makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;"
       end
    ],
    
    "android/widget/Button" => [
      Proc.new do
        NWrap.override Android::Widget::Button, "setOnClickListener", "(Landroid/view/View$OnClickListener;)V"         
      end
    ],
    
    "android/view/View" => [
      Proc.new do
        NWrap.override Android::View::View, "setOnClickListener", "(Landroid/view/View$OnClickListener;)V"         
      end
    ]    
  }  
  
  class JWrap  
    module View
      def setOnClickListener &b
        @cb = b
        super(proxy("android.view.View$OnClickListener", &@cb))
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
      @dlg
    end
    
    def is_a? what
      if what.is_a?(::String)
        if Org::Jamruby::Ext::Util.is_a(self.jobj, what)
          return true
        end
        
        return false
      end
      
      super
    end    
    
    def self.get_signature name, static=false
      sig = (static ? self::WRAP::STATIC_SIGNATURES : self::WRAP::SIGNATURES).find do |s| s[0] == name.to_s end
      if sig
        
        @p ||= NWrap.as(Java::Util::Regex::Pattern.compile("\\Q)\\EL(.*?)\;$"), Java::Util::Regex::Pattern)
        m = NWrap.as(@p.matcher(sig[1]), Java::Util::Regex::Matcher);
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
      
      (static ? singleton_class : self).define_method name do |*o|
        
        sig, as =  this.get_signature(name, static)
        cls = java.import as if as 
      
        o = (o.map do |q|
          q.respond_to?(:jobj) ? q.jobj : q
        end)    
        
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
      _new(o)
    end
    
    class << self
      alias :_new :new
    end
    
    def self.new *o
      ins = self::WRAP.new *(o.map do |q| q.respond_to?(:jobj) ? q.jobj : q end)
      wrap ins
    end
  end

  class String
    def jmatch str
      p = NWrap.as(Java::Util::Regex::Pattern.compile(str), Java::Util::Regex::Pattern)
      m = NWrap.as(p.matcher(self), Java::Util::Regex::Matcher);
    end
  end

  module JavaBridge
    def self.import path
      t = ::Object
      a = path.split("/")
      i = 0
      ot = self
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
        
        return cls 
      end
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
 
  class java::Org::Jamruby::Ext::MessageHandler
    Callbacks = []
    def on n, &b
      id = nil
      p "reg: #{n}"
      if id = registerMessage(n.to_s)
        Callbacks[id] = b
        p "reg: added #{id}"
        return true
      end
      
      raise "RegisterMessageError: could not register #{n}"
    end
    
    def dispatch id, *o 
      p "dispatch: #{id}"
      if id >=0 and cb=Callbacks[id]
        p "dispatch: call #{id}"
        cb.call *o
        p "dispatch: called"
      end 
    end
    
    def emit n, *args
      p "emit: #{n} #{messages.size}"
      if (id=messages.indexOf(n.to_s)) >= 0
        p "emit: valid name #{n}"      
        l = java::Org::Jamruby::Ext::ObjectList.create
        pushMsg id,l
        p "emit: pushed msg #{id}"
        
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
        p "emit: send msg ..."
        sendEmptyMessage(id)
        p "emit: sent"
      end
    end
  end 

  class Thread
    def self.jsleep i
      i = i * 1000.0
      java::Java::Lang::Thread.sleep i.to_i
    end
  end

  module Kernel        
    def toast str, len = 500
      tst = java::Android::Widget::Toast.makeText activity, str, len
      tst.show
      tst
    end
    
    def p *o
      o.each do |q| Android::Util::Log.i("jam", q.inspect) end
    end

    def activity
      p "get act"
      java::Org::Jamruby::Ext::JamActivity.getInstance
    end

    def handler
      p "get handle"
      activity.getHandler
    end
  end
rescue => e
  $r=e
  p $r
end