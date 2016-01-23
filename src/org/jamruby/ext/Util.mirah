package org.jamruby.ext

import java.lang.StringBuilder
import java.util.Scanner
import java.util.ArrayList
import java.io.File
import java.io.FileOutputStream
import java.io.PrintStream
import java.io.InputStream

import org.jamruby.mruby.Value;
import org.jamruby.mruby.State
import org.jamruby.mruby.MRuby

import android.util.Log

import org.jamruby.ext.JamActivity

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
  
  def self.writeFile(pth:String, content:String):void
      os = FileOutputStream.new(pth);
    begin 

      ps = PrintStream.new(os);
      ps.print(content);
      ps.close();
    rescue => e
      os.close
      p(e)
    end
  end 
  
  def self.p o:Object
    Log.i("jamutil", "#{o}")
  end
  
  def self.toValue(mrb:State, obj:Object):Value
    if obj.kind_of?(Integer)
      # Log.i "jamapp", "Make INT"
      Value.new(Integer(obj).intValue)
    elsif obj.kind_of?(Double)
      Value.new(Double(obj).doubleValue)
    elsif obj.kind_of?(Float)
      Value.new(Float(obj).floatValue)
    elsif obj.kind_of?(CharSequence)
      Log.i "jamapp", "Make String"
      MRuby.strNew(mrb, String(obj))
    else
      Log.i "jamapp", "Make NIL"
      MRuby.jobjectMake(mrb, obj)
    end
  end
  
  def self.enums e:Class
    ol = ObjectList.new
    e.getEnumConstants.each do |v|
      ol.add v
    end
    ol
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
  
  def self.isInstance(ins:Object, what:String)
    classForName(what).isInstance(ins)
  end
  
  def self.classForName(name:String):Class
    begin
      Class.forName(name)
    rescue => e
      p e
      nil
    end
  end
  
  def self.innerClassesOf(cls:Class):ObjectList
    ol = ObjectList.new
  
    cls.getClasses.each do |c|
      ol.addStr c.getName
    end
    
    return ol
  end
  
  # def self.fieldsOf(cls:Class):ObjectList
  #   # ...  
  # end
  
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
  
  def self.sendMain(m:String, ol:ObjectList):void
    JamActivity.getInstance.sendMain m, ol
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

  def self.createFileFromInputStream(path:String, inputStream:InputStream):File
    f = File.new(path);
    outputStream = FileOutputStream.new(f);
    
    begin
      buffer = byte[1024]
      length = 0;

      while ((length=inputStream.read(buffer)) > 0)
        outputStream.write(buffer,0,length);
      end

      outputStream.close();
      inputStream.close();

      return f;
    rescue => e
      outputStream.close();
      inputStream.close();
      return nil;
    end
  end 
  
  def self.objArrayGet(a:Object[], i:int):Object
    a[i]
  end    
end
