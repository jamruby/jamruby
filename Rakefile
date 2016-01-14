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
task :default => :build

desc "installs mrblibs to device:///sdcard/"
task :push do
  sh "adb shell mkdir -p /sdcard/jamruby/mrblib"
  sh "adb push ./mrblib/jamruby.mrb /sdcard/jamruby/mrblib/"
  sh "adb push ./mrblib/ui.mrb /sdcard/jamruby/mrblib/"  
  sh "adb push ./mrblib/activity.mrb /sdcard/jamruby/mrblib/"  
end

desc "compiles mrblibs in ./mrbib/"
task :mrblib do
  sh "cd mrblib && ../../mruby/build/host/bin/mrbc -o jamruby.mrb core.rb jamruby.rb kernel.rb bridge.rb native_list.rb native_view.rb native_object.rb native_wrapper.rb init.rb message_handler.rb thread.rb"  
  sh "../mruby/build/host/bin/mrbc mrblib/activity.rb"
  sh "../mruby/build/host/bin/mrbc -o mrblib/ui.mrb mrblib/view.rb"  
end
