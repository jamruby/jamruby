module JamRuby
  include Enumerable
  module NativeList
    def each &b
      to_a.each &b
    end
    
    def to_a
      a = []
      JAVA::Org::Jamruby::Ext::Util.objectListFillMrbArray(respond_to?(:native) ? native : self, a.to_java)
      a
    end
  end
end
