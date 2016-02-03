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
  sh "rm -rf assets/mrblib/*"
  sh "mkdir -p assets/mrblib/jamruby"  
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/app.mrb mrblib/jamruby/app.rb"
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/activity.mrb mrblib/jamruby/activity.rb" 
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/intent.mrb mrblib/jamruby/intent.rb" 
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/view.mrb mrblib/jamruby/view.rb"    
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/array_adapter.mrb mrblib/jamruby/array_adapter.rb"  
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/file_chooser.mrb mrblib/jamruby/file_chooser.rb" 
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/jamruby/javascript_interface.mrb mrblib/jamruby/javascript_interface.rb"         
  sh "cd mrblib/core && ../../../mruby/build/host/bin/mrbc -g -o ../../assets/mrblib/core.mrb core.rb jamruby.rb bridge.rb kernel.rb"
  sh "cd mrblib/base && ../../../mruby/build/host/bin/mrbc -g -o ../../assets/mrblib/base.mrb native_list.rb native_view.rb native_object.rb native_wrapper.rb"
  sh "cd mrblib/common && ../../../mruby/build/host/bin/mrbc -g -o ../../assets/mrblib/common.mrb init.rb"
end
