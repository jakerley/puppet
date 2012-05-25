## Simple holder for password entered on stdin
## Not threadsafe but should not be needed.
class Puppet::SSL::Ca_password
  @@password = nil
  def self.password
    return @@password
  end
  
  def self.password=(value)
    begin
      @@password = value
    rescue => detail
      raise "Cannot reset CA private key password"
    end
    self.freeze    
  end
end