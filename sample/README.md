Sample JAMRUBY Application
===

Edit `/sdcard/jamruby/org.hello.mruby/main.rb` on device to modify without reinstall    

![alt tag](https://raw.githubusercontent.com/ppibburr/jamruby/master/sample/screen.png)

Requirements
----
* android-sdk (and a target. tested against android-15)
* ant
* jruby (on path)
* mirah (jruby -S gem i mirah)

Build
----

See `rake -T`

```
  ## Set the ruby file to run. defaults to 'custom_view'
  # rake main[<name>]

  rake debug

  # rake install
  # rake push
  # rake run
```
