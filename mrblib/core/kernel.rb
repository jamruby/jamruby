require "java/lang/Thread"
module Kernel          
  def print *o
    o.each do |q| JAVA::Android::Util::Log.i("jamruby", q.to_s) end
  end  
  
  def puts *o
    print *o
  end
  
  def p *o
    o.each do |q| puts q.inspect end
  end
  
  def sleep i
    i = i * 1000.0
    JAVA::Java::Lang::Thread.sleep i.to_i
  end
  
  def java
    JamRuby::Bridge
  end   
  
  def main m, *o
    ol = o.to_object_list
    JAVA::Org::Jamruby::Ext::Util.sendMain m.to_s, ol.native
  end
end
  
def on_pause
  puts "on_pause"
end

def on_resume
  puts "on_resume"
end

def on_stop
  puts "on_stop"
end

def on_start
  puts "on_start"
end

def on_restart
  puts "on_restart"
end

def on_destroy

end
