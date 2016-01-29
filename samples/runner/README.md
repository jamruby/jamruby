Sample JAMRUBY Application
===
Runs Activity's defined in ruby scripts.  

Scripts stored at `/sdcard/jamruby/scripts/org.hello.runner/samples/` on device.      

![alt tag](https://raw.githubusercontent.com/ppibburr/jamruby/master/samples/runner/screen.png)

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
