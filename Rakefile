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
  sh "adb push ./mrblib/jam_mrblib.mrb /sdcard/"
  sh "adb push ./mrblib/jam_activity.mrb /sdcard/"  
end

desc "compiles mrblibs in ./mrbib/"
task :mrblib do
  sh "../mruby/build/host/bin/mrbc ./mrblib/jam_mrblib.rb"
  sh "../mruby/build/host/bin/mrbc ./mrblib/jam_activity.rb"  
end
