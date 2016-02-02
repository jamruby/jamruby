Sample JAMRUBY Application
===

Edit `/sdcard/jamruby/org.hello.mruby/main.rb` on device to modify without reinstall    

<img height=25% src=https://raw.githubusercontent.com/ppibburr/jamruby/master/samples/runner/screen.png></img>

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
  rake debug

  # rake install
  # rake run
```
