## Simple utility to capture a password on stdin.
## 
class Password_utils
  def self.capturepassword
    system "stty -echo"
    print "Enter CA private key passsword:"
    password = STDIN.gets.strip
    system "stty echo"
    puts    
    password
  end
end