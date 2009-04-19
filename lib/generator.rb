class Generator
  include Singleton
  cattr_accessor :act_on, :actors
  
  def self.load(what)
    self.actors ||= []
    self.actors << self.act_on if self.act_on
    self.act_on = what
  end

  def self.unload
    self.act_on = self.actors.shift
  end

  def self.method_missing(sym, *args)
    act_on.send(sym, *args)
  end
end


