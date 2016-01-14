module JamRuby
  class NativeObject
    # Look up Fields
    def self.const_missing c
      pth = self::WRAP::CLASS_PATH.split("/").join(".")
      cls = ::JAVA::Org::Jamruby::Ext::Util.classForName(pth )
      if r = ::JAVA::Org::Jamruby::Ext::FieldHelper.getField(cls, c.to_s)
        return r
      end 
      
      super
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
      extend JamRuby::NativeView if obj.respond_to?(:setOnClickListener)
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
        
        @p ||= NativeWrapper.as(JAVA::Java::Util::Regex::Pattern.compile("\\Q)\\EL(.*?)\;$"), JAVA::Java::Util::Regex::Pattern)
        m = NativeWrapper.as(@p.matcher(sig[1]), JAVA::Java::Util::Regex::Matcher);
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
      
      args    
    end
  end
end
