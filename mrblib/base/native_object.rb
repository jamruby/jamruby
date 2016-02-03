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
      JAVA::Java::Lang::Class.forName(path)
    end
  end
  
  class NativeObject
    def self.java_class
      NativeClassHelper.classForName self::WRAP::CLASS_PATH.split("/").join(".")
    rescue => e
      p e
    end 
    
    def self.native
      java_class
    end   
  
    # Look up Fields
    def self.const_missing c
      pth = self::WRAP::CLASS_PATH.split("/").join(".")
      cls = NativeClassHelper.classForName pth
     
      if NativeClassHelper.is_enum? cls
        begin
          v = NativeClassHelper.get_enum(cls, c.to_s)
          const_set c, v
          return v
        rescue => e
          super
        end
      end
      
      if ::JAVA::Org::Jamruby::Ext::FieldHelper.hasField(cls, c.to_s)
        r = ::JAVA::Org::Jamruby::Ext::FieldHelper.getField(cls, c.to_s)
        const_set c, r
        return r
      end 
      
      if ::JAVA::Org::Jamruby::Ext::FieldHelper.hasField(cls, c.to_s.uncapitalize)
        r = ::JAVA::Org::Jamruby::Ext::FieldHelper.getField(cls, c.to_s.uncapitalize)
        const_set c, r
        return r
      end               
      
      super
    end   
  
    def self.set_for t
      cls = self
      t.class_eval do
        const_set :BRIDGE, cls
        singleton_class.define_method "bridge" do
          const_get(:BRIDGE)
        end
      end
      self.const_set :WRAP, t
    end
    
    def __to_str__
      c=native.jclass
      m = c.get_method "toString","()Ljava/lang/String;"
      c.call native, m
    end
    
    def inspect
      __to_str__
    end
    
    def to_str
      __to_str__
    end
    
    def to_s
      __to_str__
    end
    
    def initialize obj
      @native = obj 
      extend JamRuby::NativeView if obj.respond_to?(:setOnClickListener)
    end
    
    def native
      q = @native
      while q.respond_to?(:native)
        q = q.native
      end
      
      q
    end
    
    def is_a? what
      if what.is_a?(::String)
        if JAVA::Org::Jamruby::Ext::Util.isInstance(self.native, what)
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
    
    def self.sigs
      @sigs ||= {}
      @sigs[:static]  ||= {}
      @sigs[:instance] ||= {}
      @sigs
    end
    
    def self.add_method name, static = false
      this = self

      (static ? singleton_class : self).define_method name do |*o, &b|
        unless this.sigs[static ? :static : :instance][name]
          a = []
          a.push *this.get_signature(name, static)
          a << java.import(a[1]) if a[1]  
          this.sigs[static ? :static : :instance][name] = a
        end

        sig, as, cls = this.sigs[static ? :static : :instance][name]

      
        o = this.adjust_args sig, *o, &b    
        
        if static
          res = this::WRAP.send name, *o       
        else  
          if native.is_a?(this::WRAP)
            res = native.send name, *o
          else
            c=native.jclass
            m=c.get_method(name, sig[1])
            res = c.call(native, m, *o)
          end
        end
          
        if as
          return cls.wrap(res)
        end
          
        return res
      end
    end
    
    def self.wrap o
       o = o.respond_to?(:native) ? o.native : o
       _new(o)
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
            t.name = data[0][1..-1]
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
        next q.native if q.respond_to?(:native)

        i += 1
        if q.is_a? Symbol
          begin
            const_get :"#{q.to_s.upcase}"
          rescue
            next q unless sig
            
            type = arg_type(sig, i)
            
            if type.qualified and NativeClassHelper.is_enum?(NativeClassHelper.classForName(type.name.split("/").join(".")))
              java.import type.name
              iface = java.import type.name, true
              next iface.const_get(:"#{q.to_s.upcase}")
            end
            
            next q
          end
        else
          q
        end
      end
      
      # Create proxy
      if b
        type = arg_type(sig, arg_types(sig).length-2)

        if type.qualified
          pc = JamRuby::Proxy.for(type.name.split("/").join("."))
          pxy = pc.new(&b)
          args << pxy.native
        else
          
        end
      end

      args
    rescue => e
      p e
    end
  end
end
