require "java/util/regex/Pattern"
require "java/util/regex/Matcher"
require "android/util/Log"
require "org/jamruby/ext/Util"
require "org/jamruby/ext/ObjectList"

module JamRuby
  VERSION = "0.0.3"

  IMPORT_OVERLOADS = {
    "android/widget/Toast" => [
       Proc.new do
         NativeWrapper.static_override JAVA::Android::Widget::Toast, "makeText", "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;"
       end
    ],
    
    "android/widget/Button" => [
      Proc.new do
        NativeWrapper.override JAVA::Android::Widget::Button, "setText", "(Ljava/lang/CharSequence;)V"       
      end
    ],
    
    "android/view/View" => [
      Proc.new do
        JAVA::Android::View::View.implement JamRuby::NativeView  
      end
    ],  
    
    "android/widget/TextView" => [
      Proc.new do
        NativeWrapper.override JAVA::Android::Widget::TextView, "setText", "(Ljava/lang/CharSequence;)V"  
      end
    ],
    
    "android/widget/EditText" => [
      Proc.new do
        NativeWrapper.override JAVA::Android::Widget::EditText, "getText", "()Landroid/text/Editable;"  
      end
    ],    
    
    "org/jamruby/ext/ObjectList" => [
      Proc.new do
        JAVA::Org::Jamruby::Ext::ObjectList.implement JamRuby::List  
      end
    ],
    
    "java/util/ArrayList" => [
      Proc.new do
        JAVA::Org::Jamruby::Ext::ObjectList.implement JamRuby::List
      end
    ]     
  }  
end 


