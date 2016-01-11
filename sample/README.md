Sample JAMRUBY Application
===

Loads ruby file from /sdcard/ and creates `Activity`.  
`Activity` will have a `Button` with `OnClickListener`  
`Button` wil have its text updated from a loop in a `Thread`  

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
  rake debug
  
  # rake install
  # rake push
  # cd .. && rake mrblib
  # cd .. && rake push
  # rake run
```
