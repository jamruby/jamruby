class Module
  def implement mod
    class_eval do
      include mod
    end
  end
end


class String
  def jmatch str
    p = NativeWrapper.as(JAVA::Java::Util::Regex::Pattern.compile(str), JAVA::Java::Util::Regex::Pattern)
    m = NativeWrapper.as(p.matcher(self), JAVA::Java::Util::Regex::Matcher);
  end
end

class JObject
  def as what
    what.wrap self
  end
end 
