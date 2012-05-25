## Simple utility to capture a password on stdin.
## 
module Puppet::Util::Password_utils
  def self.capturepassword
    system "stty -echo"
    begin
      begin
        print "Enter CA private key password:"        
        password = STDIN.gets.strip
        puts        
      end while( password == "")
    ensure
      system "stty echo"
    end    
    password
  end
end