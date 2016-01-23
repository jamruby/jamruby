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
  sh "../mruby/build/host/bin/mrbc -g -o assets/mrblib/activity.mrb mrblib/activity/activity.rb mrblib/activity/view.rb"
  sh "cd mrblib/core && ../../../mruby/build/host/bin/mrbc -g -o ../../assets/mrblib/core.mrb core.rb jamruby.rb bridge.rb kernel.rb"
  sh "cd mrblib/jamruby && ../../../mruby/build/host/bin/mrbc -g -o ../../assets/mrblib/jamruby.mrb native_list.rb native_view.rb native_object.rb native_wrapper.rb"
  sh "cd mrblib/thread && ../../../mruby/build/host/bin/mrbc -g -o ../../assets/mrblib/thread.mrb init.rb"

end
