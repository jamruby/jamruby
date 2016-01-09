Sample JAMRUBY Application
===

Loads ruby file from /sdcard/ and creates `Activity`.  
`Activity` will have a `Button` with `OnClickListener`  
`Button` wil have its text updated from a loop in a `Thread`  


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
