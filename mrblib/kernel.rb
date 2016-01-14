module Kernel        
  def toast str, len = 500
    tst = Android::Widget::Toast.makeText activity, str, len
    tst.show
    tst
  end
  
  def print *o
    o.each do |q| JAVA::Android::Util::Log.i("jam_mrblib.mrb", q.inspect) end
  end  
  
  def puts *o
    print *o
  end
  
  def p *o
    o.each do |q| print q.inspect end
  end

  def activity
    Org::Jamruby::Ext::JamActivity.getInstance
  end

  def handler
    activity.getHandler
  end
  
  def sleep amt
    Thread.jsleep amt
  end
  
  def java
    JamRuby::Bridge
  end   
end
