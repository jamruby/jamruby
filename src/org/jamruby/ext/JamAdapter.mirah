package org.jamruby.ext

import android.widget.ArrayAdapter
import android.R.layout as AndroidLayout
import android.content.Context
import java.util.ArrayList

class JamAdapter < ArrayAdapter
  def initialize c:Context, q:int, items:ArrayList
    super c, q, items
  end

  def self.create c:Context, items:ArrayList
    a = new(c, AndroidLayout.simple_list_item_1, items)
  end
  
  def toArrayAdapter():ArrayAdapter
    ArrayAdapter(self)
  end
end
