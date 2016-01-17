module JamRuby
  module NativeClassHelper
    def self.is_enum? cls
      m = cls.jclass.get_method "isEnum", "()Z"
      cls.jclass.call cls, m
    end
    
    def self.get_enum c, e
      ea = NativeWrapper.as(JAVA::Org::Jamruby::Ext::Util.enums(c), JAVA::Org::Jamruby::Ext::ObjectList)
      ea.get( ea.to_s[1..-2].split(",").join.split(" ").index(e.to_s.upcase))
    end  
    
    def self.classForName(path)
     JAVA::Org::Jamruby::Ext::Util.classForName(path)
    end
  end
  
  class NativeObject
    # Look up Fields
    def self.const_missing c
      pth = self::WRAP::CLASS_PATH.split("/").join(".")
      cls = NativeClassHelper.classForName pth
     
      if ::JAVA::Org::Jamruby::Ext::FieldHelper.hasField(cls, c.to_s)
        r = ::JAVA::Org::Jamruby::Ext::FieldHelper.getField(cls, c.to_s)
        return r
      end 
     
      if NativeClassHelper.is_enum? cls
        begin
          v = NativeClassHelper.get_enum(cls, c.to_s)
          return v
        rescue => e
          super
        end
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
      
        o = this.adjust_args sig, *o, &b    
        
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
      ins = self::WRAP.new *adjust_args(nil,*o,&b)
      wrap ins
    end
    
    class NType
      attr_accessor :array, :name, :qualified
    end
    
    def self.arg_types sig
      types = []
      sig = sig[1].split(")")[0][1..-1]
      while sig != ""
        if c=["[", "L"].find do |q| sig[0..0] == q end
          types << t=NType.new
          if c == "["
            t.array = true
            sig = sig[1..-1]
          elsif c == "L"
            t.qualified = true
            data = sig.split(";")
            t.name = data[0][1..-1].split("/").join(".")
            sig = sig[1] || ""
          end
        else
          types << t=NType.new
          t.name = sig[0..0]
          if sig.length > 1
            sig = sig[1..-1]
          else
            sig = ""
          end
        end
      end
      
      types
    rescue => e
      p e
    end
    
    def self.arg_type sig, i
      arg_types(sig)[i]
    rescue => e
      p e
    end
    
    def self.adjust_args sig, *o,&b
      i = -1
      args = o.map do |q|
        next q.jobj if q.respond_to?(:jobj)

        i += 1
        if q.is_a? Symbol
          begin
            const_get :"#{q.to_s.upcase}"
          rescue
            next q unless sig
            type = arg_type(sig, i)

            if type.qualified and NativeClassHelper.is_enum?(cls=NativeClassHelper.classForName(type.name))
              if (v=NativeClassHelper.get_enum(cls, q)) != nil
                next v
              end
            end
            
            next q
          end
        else
          q
        end
      end
      
      if b
        args << proxy("java.lang.Runnable", &b)
      end
      
      args
    rescue => e
      p e
    end
  end
end
