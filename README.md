jamruby
====

__jamruby__ is Java to mruby bridge.

Requirements
----
* android-ndk
* jruby
* mirah  

Build
----
See `build_config.rb` as exampe of mruby build  
We expect mruby source to be one level above from inside `./jamruby`  

```
# export JRUBY_ROOT=/home/ppibburr/jruby-1.7.23
# export ANDROID_NDK_HOME=/path/to/ndk
# export ANDROID_HOME=/home/ppibburr/android-sdk-linux
# export PATH=$PATH:$ANDROID_NDK_HOME
# export PATH=$PATH:$ANDROID_HOME/tools
# export PATH=$PATH:$ANDROID_HOME/platform-tools
# export PATH=$PATH:$JRUBY_ROOT/bin

# export ANDROID_STANDALONE_TOOLCHAIN=/home/ppibburr/tc

# git clone https://github.com/mruby/mruby

git clone https://github.com/ppibburr/jamruby

# cp jamruby/build_config.rb mruby/build_config.rb
# cd mruby
# make
# cd ..

# jruby -S gem i mirah

cd jamruby
rake

## compiles mrblibs
# rake mrblib
## installs mrblibs to device
# rake push
```

Using
----
jamruby is a NDK library to be included in your Application.  
See `./sample` for an example application using this library.  



License
----

__MIT License__

Copyright (c) 2012-2016 jamruby developers

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

