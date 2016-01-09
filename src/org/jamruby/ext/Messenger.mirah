package org.jamruby.ext

import ObjectList
import android.os.Handler.Callback
import android.os.Handler
import android.os.Looper

class MessageHandler < Handler
  def initialize l:Looper, c:MessengerCallback
    super l, Callback(c)
    
    @callback = c
    
    c.setHandler self
    
    @messages = ObjectList.create
    @msgArgs  = ObjectList.create    
  end
  
  def callback
    @callback
  end
  
  def messages
    @messages
  end
  
  def pushMsg id:int, ol:ObjectList
    if @msgArgs.size > id
      ObjectList(@msgArgs.get(id)).addObj(ol)
      return true
    end
    
    return false
  end
  
  def popMsg(id:int):ObjectList
    begin
    if @msgArgs.size <= id
      return ObjectList(nil)
    end
    
    if ObjectList(@msgArgs.get(id)).size < 1
      return nil
    end
  
    ol = ObjectList(@msgArgs.get(id)).get(0)
    ObjectList(@msgArgs.get(id)).remove(0)
    
    return ObjectList(ol)
    
    rescue => e
      return nil
    end
  end
  
  def registerMessage(name:String):int
    id = -1
    
    if (id = @messages.indexOf(name)) >= 0
      return id
    end
    
    @messages.addStr(name)
    @msgArgs.addObj(l=ObjectList.create)
    
    if (id=@msgArgs.indexOf(l)) != @messages.indexOf(name)
      return -1
    end
    
    return id
  end  
end

interface MessageRunner do
  def run(ol:ObjectList):void
  end
end

class MessengerCallback
  implements Callback
  def initialize proxy:MessageRunner
    super()
    @proxy = proxy
  end
  
  def setHandler handler:MessageHandler
    @handler = handler
  end
  
  def getHandler
    @handler
  end
  
  def handleMessage msg
    id = msg.what
    ol = handler.popMsg id
    ol.add(0, msg.what)
    @proxy.run ol
    true
  end
  
  def getProxy():MessageRunner
    @proxy
  end
  
  def setProxy(proxy:MessageRunner):void
    @proxy = proxy
  end
end
