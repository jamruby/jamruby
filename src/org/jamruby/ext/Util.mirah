package org.jamruby.ext

import java.lang.StringBuilder
import java.util.Scanner
import java.util.ArrayList
import java.io.File

import org.jamruby.mruby.Value;
import org.jamruby.mruby.State
import org.jamruby.mruby.MRuby

import android.util.Log

class Util
	def self.readFile(pathname:String)

		file = File.new(pathname);
		fileContents = StringBuilder.new(int(file.length()));
		scanner = Scanner.new(file);
		lineSeparator = System.getProperty("line.separator");

		begin
			while(scanner.hasNextLine())        
				fileContents.append(scanner.nextLine() + lineSeparator);
			end
			
			return fileContents.toString();
		rescue
			scanner.close();
			
			return ""
		end
	end
  
  def self.writeFile(pth:String):void
  end 
  
  def self.toValue(mrb:State, obj:Object):Value
    if obj.kind_of?(Integer)
      # Log.i "jamapp", "Make INT"
      Value.new(Integer(obj).intValue)
    elsif obj.kind_of?(Double.TYPE)
      Value.new(Double(obj).doubleValue)
    elsif obj.kind_of?(Float.TYPE)
      Value.new(Float(obj).floatValue)
    elsif obj.kind_of?(CharSequence)
      MRuby.strNew(mrb, String(obj))
    else
      # Log.i "jamapp", "Make NIL"
      MRuby.nilValue()
    end
  end
  
  def self.is_a(ins:Object, what:String)
    begin  
      if ins.kind_of?(Class.forName(what))
        return true
      end
      return false
    rescue
      return false
    end
  end
  
  def self.arrayListToValueArray(mrb:State, al:ArrayList):Value[]
    va = Value[al.size]
    
    i = 0
    
    al.each do |a|
      Log.i "jamapp", "Make Value: #{a}"
      va[i] = toValue(mrb, a)
      i+=1
    end
    
    Log.i "jamapp", "Make Value: #{i}"  
    
    return va
  end
  
  def self.objectArrayToValueArray(mrb:State, oa:Object[]):Value[]
    va = Value[oa.length]
    
    i = 0
    
    oa.each do |a|
      Log.i "jamapp", "Make Value: #{a}"
      va[i] = toValue(mrb, a)
      i+=1
    end
    
    Log.i "jamapp", "Make Value: #{i}"  
    
    return va
  end      
end
