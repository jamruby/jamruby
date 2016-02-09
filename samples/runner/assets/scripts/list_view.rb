java.import "android/widget/ListView"   

require "jamruby/array_adapter"

class Main < JamRuby::Activity
  def on_create state
    data  = ["Apples", "Oranges", "Steak", "Cheese"]
    aa    = JamRuby::ArrayAdapter.new(self, data)
    lv    = Android::Widget::ListView.new self
    
    lv.setAdapter aa
    
    lv.setOnItemClickListener do |list_view, view, pos, id|
      toast "Item #{pos}: #{data[pos]}"
    end
    
    setContentView lv
  end
end

