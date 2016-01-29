java.import "org/jamruby/runner/SpawnedActivity"
java.import "android/widget/ListView"   

class Main < JamRuby::Activity
  def on_create state
    files = ["#{getBaseDir}/custom_view.rb", "#{getBaseDir}/thread.rb","#{getBaseDir}/multi_progress.rb","#{getBaseDir}/download.rb"]
    aa    = JamRuby::ArrayAdapter.new(self, files.map do |f| File.basename f end)
    lv    = Android::Widget::ListView.new self
    
    lv.setAdapter aa
    
    lv.setOnItemClickListener do |q,e, id, n|
      intent = JamRuby::Intent.createComponent(getBaseContext, Org::Jamruby::Runner::SpawnedActivity)
      intent.putExtra("org.jamruby.runner.spawned.MAIN", "#{files[id]}")
      intent.setFlags(Android::Content::Intent::FLAG_ACTIVITY_CLEAR_TASK);
      
      startActivity intent
    end
    
    setContentView lv
  end
end

