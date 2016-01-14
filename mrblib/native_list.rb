module JamRuby
  module NativeList
    def each &b
      this = NativeWrapper.as(self, JAVA::Org::Jamruby::Ext::ObjectList)
      for i in 0..this.size-1
        b.call this.get(i)
      end
    end
  end
end
