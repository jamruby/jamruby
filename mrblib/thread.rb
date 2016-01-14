java.import "java/lang/Thread"

class Thread
  def self.jsleep i
    i = i * 1000.0
    Java::Lang::Thread.sleep i.to_i
  end
end
