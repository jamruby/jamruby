begin  
  java.import "android/widget/ArrayAdapter"
  java.import "org/jamruby/ext/JamAdapter"  
  module JamRuby
    class ArrayAdapter < Android::Widget::ArrayAdapter
      def initialize context, items
        @native = Org::Jamruby::Ext::JamAdapter.create(context, items).toArrayAdapter.native
      end

      def self.new context, items
        _new(context, items)
      end
    end
  end
rescue => e
  p e
  raise e
end
