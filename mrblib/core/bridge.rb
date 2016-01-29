__eval__ "require 'java/lang/Class'"

module JamRuby
  module Bridge
    # Binds Java Class to Ruby
    #
    # @param [String] path the class to import
    # @param [Boolean] bool internal use
    #
    # @return [Class] 
    def self.import path, bool=false
      __eval__ "java.__import__ '#{path}', #{bool}"
    end
    
    def self.__import__ path, bool=false
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
          
          __eval__ "require '#{path}'"
          
          if q=JamRuby::IMPORT_OVERLOADS[path]
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
        ot.const_set(:"#{sym}", cls=Class.new(JamRuby::NativeObject))
        
        cls.set_for t
        
        t::SIGNATURES.each do |o|
          cls.add_method o[0]
        end
        
        t::STATIC_SIGNATURES.each do |o|
          cls.add_method(o[0], true) unless o[0] == "new"
        end
        
        get_inner_classes(path).each do |ic|
          java.__import__(z=ic.to_s, z.index(path))
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
      o = JAVA::Org::Jamruby::Ext::Util.innerClassesOf(JamRuby::NativeClassHelper.classForName(pth.split("/").join(".")))
      o.extend NativeList
      o
    end   
  end 
end
