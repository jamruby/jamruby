module JamRuby
  include Enumerable
  module NativeList
    def each &b
      this = respond_to?(:native) ? self : NativeWrapper.as(self, JAVA::Org::Jamruby::Ext::ObjectList)
      for i in 0..this.size-1
        b.call this.get(i)
      end
    end
    
    def to_a
      a = []
      JAVA::Org::Jamruby::Ext::Util.objectListFillMrbArray(respond_to?(:native) ? native : self, a.to_java)
      a
    end
  end
end
