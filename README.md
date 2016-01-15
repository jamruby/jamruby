jamruby
====

__jamruby__ is Java to mruby bridge.  
Android applications can be scripted with Ruby!  

Features
----
* Script in Ruby
* Use .rb or .mrb (bytecode) files from storage
* Threads (Uses mattn/mruby-thread)
* Events
* UI Access

Sample
----
```ruby
  java.import "android/widget/Button"

  b = Android::Widget::Button.new(activity)
  b.setText "Click Me!"  
  b.setOnClickListener() do
    tst = toast "ouch!"
  end

  activity.setContentView b
```

Requirements
----
* android-ndk (ndk-build must be on path)
* jruby  (must be on path)
* mirah  (jruby -S gem i mirah)

Build
----
The following builds native library.  

See `build_config.rb` as exampe of mruby build  
We expect mruby source to be one level above from inside `./jamruby`  

```
# git clone https://github.com/mruby/mruby

git clone https://github.com/ppibburr/jamruby

# cp jamruby/build_config.rb mruby/build_config.rb
# cd mruby
# make
# cd ..

# jruby -S gem i mirah


cd jamruby

## See 'rake -T'
rake
```

Using
----
jamruby is a NDK library to be included in your Application.  
See `./sample` for an example application using this library.  

projects can be built from command line usung `ant`



License
----

__MIT License__

Copyright (c) 2012-2016 jamruby developers

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

