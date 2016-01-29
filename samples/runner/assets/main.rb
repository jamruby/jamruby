java.import "org/jamruby/runner/SpawnedActivity"
java.import "android/widget/ListView"   

class Main < JamRuby::Activity
  def on_create state
    files = Dir.entries(getBaseDir).find_all do |f| 
      f.split(".").last == "rb"
    end
    
    aa    = JamRuby::ArrayAdapter.new(self, files)
    lv    = Android::Widget::ListView.new self
    
    lv.setAdapter aa
    
    lv.setOnItemClickListener do |list_view, view, pos, id|
      intent = JamRuby::Intent.createComponent(getBaseContext, Org::Jamruby::Runner::SpawnedActivity)
      intent.putExtra("org.jamruby.runner.spawned.MAIN", "#{getBaseDir}/#{files[pos]}")
      intent.setFlags(Android::Content::Intent::FLAG_ACTIVITY_CLEAR_TASK);
      
      startActivity intent
    end
    
    setContentView lv
  end
end

