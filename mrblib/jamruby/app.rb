n = JAM_CONF[:no_inner]
JAM_CONF[:no_inner] = true
java.import "android/widget/Toast"

require "jamruby/intent"
require "jamruby/activity"
JAM_CONF[:no_inner]=n


