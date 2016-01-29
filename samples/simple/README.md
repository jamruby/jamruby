Sample JAMRUBY Application
===

Edit `/sdcard/jamruby/org.hello.mruby/main.rb` on device to modify without reinstall    

![alt tag](https://raw.githubusercontent.com/ppibburr/jamruby/master/samples/simple/screen.png)

Requirements
----
* android-sdk (and a target. tested against android-15 and android-16)
* ant
* jruby (on path)
* mirah (jruby -S gem i mirah -v 0.1.5.dev)

Build
----

See `rake -T`

```
  ## Set the ruby file to run. defaults to 'custom_view' (./scripts/custom_view.rb)
  # rake main[<name>]

  rake debug

  # rake install
  # rake run
```
