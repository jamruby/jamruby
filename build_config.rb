MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  # include the default GEMs
  conf.gembox 'default'

  # mrbc settings
  conf.mrbc do |mrbc|
    mrbc.compile_options = "-g -B%{funcname} -o-" # The -g option is required for line numbers
  end
  
  conf.gem 'mrbgems/mruby-print'
  conf.gem 'mrbgems/mruby-compiler'
  conf.gem 'mrbgems/mruby-string-ext'  
  conf.gem :github=>"iij/mruby-io" 
  conf.gem :github=>"ppibburr/mruby-simplehttp"   
  conf.gem :github=>"ppibburr/mruby-httprequest" 
  conf.gem :github=>"ppibburr/pbr-download"  
end

MRuby::CrossBuild.new('android-armeabi') do |conf|
  toolchain :android
  conf.cc.flags << '-DHAVE_PTHREADS'

  # mrbc settings
  conf.mrbc do |mrbc|
    mrbc.compile_options = "-g -B%{funcname} -o-" # The -g option is required for line numbers
  end

  conf.gem 'mrbgems/mruby-print'
  conf.gem 'mrbgems/mruby-compiler'
  conf.gem 'mrbgems/mruby-string-ext'  
  conf.gem :github=>"iij/mruby-io" 
  conf.gem :github=>"matsumoto-r/mruby-simplehttp"   
  conf.gem :github=>"matsumoto-r/mruby-httprequest" 
  conf.gem :github=>"ppibburr/pbr-download"    
end

MRuby::CrossBuild.new('android-armeabi-v7a') do |conf|

  toolchain :android, :arch=>:'armeabi-v7a'
  conf.cc.flags << '-DHAVE_PTHREADS'

  # mrbc settings
  conf.mrbc do |mrbc|
    mrbc.compile_options = "-g -B%{funcname} -o-" # The -g option is required for line numbers
  end

  conf.gem 'mrbgems/mruby-print'
  conf.gem 'mrbgems/mruby-compiler'  
  conf.gem 'mrbgems/mruby-string-ext'  
  conf.gem :github=>"iij/mruby-io" 
  conf.gem :github=>"matsumoto-r/mruby-simplehttp"   
  conf.gem :github=>"matsumoto-r/mruby-httprequest" 
  conf.gem :github=>"ppibburr/pbr-download"    
end

MRuby::CrossBuild.new('android-x86') do |conf|
  toolchain :android, :arch=>:x86
  conf.cc.flags << '-DHAVE_PTHREADS'

  # mrbc settings
  conf.mrbc do |mrbc|
    mrbc.compile_options = "-g -B%{funcname} -o-" # The -g option is required for line numbers
  end

  conf.gem 'mrbgems/mruby-print'
  conf.gem 'mrbgems/mruby-compiler'
  conf.gem 'mrbgems/mruby-string-ext'  
  conf.gem :github=>"iij/mruby-io" 
  conf.gem :github=>"matsumoto-r/mruby-simplehttp"   
  conf.gem :github=>"matsumoto-r/mruby-httprequest" 
  conf.gem :github=>"ppibburr/pbr-download"   
end

