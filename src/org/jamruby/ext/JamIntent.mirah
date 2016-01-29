package org.jamruby.ext

import android.content.Intent
import android.content.Context
import android.net.Uri

class JamIntent
  def self.create
    Intent.new
  end
  
  def self.createCopy o:Intent
    Intent.new o
  end
  
  def self.createAction a:String
    Intent.new a
  end
  
  def self.createActionWithUri a:String, u:Uri
    Intent.new a, u
  end
  
  def self.createComponent c:Context, cls:Class
    Intent.new c, cls
  end
  
  def self.createComponentWithAction a:String, u:Uri, c:Context, cls:Class
    Intent.new a, u, c, cls
  end
end
