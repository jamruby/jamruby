Sample JAMRUBY Application
===

Loads ruby file from /sdcard/ and creates `Activity`.  
`Activity` will have a `LinearLayout` set to `VERTICAL`  
`LinearLayout` will have a `TextView` that fills extra space.  
`LinearLayout` will have a `Button` with `OnClickListener`  
`Button` will `toast` a message when clicked.  

A `Thread` will be ran that updates `TextView` displaying how many times the loop in the `Thread` ran.     

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
  
  ### cd .. && rake mrblib && cd sample
  ## cd .. && rake push && cd sample
  
  # rake run
```
