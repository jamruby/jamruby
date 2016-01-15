desc "Cleans native library build"
task :clean do
  sh "cd jni && ndk-build clean"
  sh "ant clean"
end 

desc "Builds native library"
task :build do
  sh "cd jni && ndk-build"
end

desc "Builds native library"
task :default => [:build, :libs]


desc "compiles extra mrblibs in ./mrblib/"
task :libs do
  sh "mkdir -p assets/mrblib"
  sh "rm -f assets/mrblib/*.mrb"
  sh "../mruby/build/host/bin/mrbc -o assets/mrblib/activity.mrb mrblib/activity.rb"
  sh "../mruby/build/host/bin/mrbc -o assets/mrblib/view.mrb mrblib/view.rb" 
  sh "cd mrblib && ../../mruby/build/host/bin/mrbc -o ../assets/mrblib/jamruby.mrb core.rb jamruby.rb kernel.rb bridge.rb native_list.rb native_view.rb native_object.rb native_wrapper.rb init.rb message_handler.rb thread.rb"
end
