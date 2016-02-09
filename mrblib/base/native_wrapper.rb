module JamRuby
  module NativeWrapper
    def method_missing m,*o
      @classes.reverse.each do |cls|
        if sig = cls::SIGNATURES[m.to_s]
          begin
            if jim = jclass.get_method(m.to_s, sig)
              return jclass.call self, jim, *(o.map do |q| q.respond_to?(:native) ? q.native : q end)
            end
          rescue
          end
        end
      end
      
      super
    end
    
    def self.override cls, m, sig
      cls::SIGNATURES[m] = sig
      
      cls.class_eval do
        define_method m do |*o|
          if jim = jclass.get_method(m, sig)
            return jclass.call self, jim, *(o.map do |q| q.respond_to?(:native) ? q.native : q end)
          end
          
          raise "NoMethodError: undefined method #{m} for #{inspect}"
        end
      end
    end
    
    def self.static_override cls, m, sig
      cls::STATIC_SIGNATURES[m] = sig
      
      n=cls.define_singleton_method m do |*o|
        if sm = (jclass=JAVA.find_class(cls::CLASS_PATH)).get_static_method(m, sig)
          return jclass.call_static sm, *(o.map do |q| q.respond_to?(:native) ? q.native : q end)
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
end
