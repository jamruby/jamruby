module JamRuby
  include Enumerable
  module NativeList
    def each &b
      this = NativeWrapper.as(self, JAVA::Org::Jamruby::Ext::ObjectList)
      for i in 0..this.size-1
        b.call this.get(i)
      end
    end
    
    def to_a
      a = []
      each do |q| a << q end
      a
    end
  end
end
