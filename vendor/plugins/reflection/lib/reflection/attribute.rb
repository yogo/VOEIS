class ReflectedAttribute
  attr_accessor :name, :type, :is_null, :default_val, :primary_key, :relationships
  
  def initialize(name, type, is_null, default_val, primary_key, relationships=nil)
    self.name        = name
    self.type        = type
    self.is_null     = is_null
    self.default_val = default_val
    self.primary_key = primary_key
  end
  
end