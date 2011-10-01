# core lib monkey patchery

class Array
  # get a random element
  def random
    self[rand length]
  end
end

class Time
  # seconds since self
  def since
    Time.now - self
  end

  # seconds until self
  def until
    self - Time.now
  end
end

class Numeric
  def seconds; self end
  def minutes; self * 60.seconds end
  def hours;   self * 60.minutes end
  def days;    self * 24.hours end
  def weeks;   self * 7.days end

  %w(second minute hour day week).each do |m|
    alias_method m, "#{m}s"
  end

  # time self seconds ago, from now or from
  def ago from=Time.now
    from - self
  end

  # time self seconds ahead, from now or from
  def ahead from=Time.now
    from + self
  end
end

class Module
  # shortcut for a long list of autoloaded constants
  # module A
  #   provides :B, :C
  # end
  # will autoload A::B and A::C from a/b.rb and a/c.rb
  def provides *syms
    dir = File.expand_path caller[0][/[^.]+/]
    syms.each do |sym|
      str = "#{dir}/#{sym.to_s.downsize}"
      autoload sym, str
    end
  end
end

class String
  # BigDog -> big_dog
  def downsize
    s = self.dup
    s.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    s.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    s.downcase!
    s
  end
end
