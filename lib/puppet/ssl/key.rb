require 'puppet/ssl/base'
require 'puppet/indirector'
require 'puppet/ssl/ca_password'

# Manage private and public keys as a pair.
class Puppet::SSL::Key < Puppet::SSL::Base
  wraps OpenSSL::PKey::RSA

  extend Puppet::Indirector
  indirects :key, :terminus_class => :file

  # Because of how the format handler class is included, this
  # can't be in the base class.
  def self.supported_formats
    [:s]
  end

  attr_accessor :password_file

  # Knows how to create keys with our system defaults.
  def generate
    Puppet.info "Creating a new SSL key for #{name}"
    @content = OpenSSL::PKey::RSA.new(Puppet[:keylength].to_i)
  end

  def initialize(name)
    super

    if ca?
      @password_file = Puppet[:capass]
    else
      @password_file = Puppet[:passfile]
    end
  end

  def read_password_file
    return nil unless password_file and FileTest.exist?(password_file)

    ::File.read(password_file)
  end

  # Optionally support specifying a password file.
  def read(path)
    if ca? && Puppet.settings[ :caexplicitpassword] == true 
      @content = wrapped_class.new(::File.read(path), Puppet::SSL::Ca_password.password)
    else
      return super unless password_file
      @content = wrapped_class.new(::File.read(path), read_password_file)
    end
  end

  def to_s
    if ca? && Puppet.settings[ :caexplicitpassword] == true   
      @content.export(OpenSSL::Cipher::DES.new(:EDE3, :CBC), Puppet::SSL::Ca_password.password)        
    else
      if pass = read_password_file
        @content.export(OpenSSL::Cipher::DES.new(:EDE3, :CBC), pass)
      else
        return super
      end
    end
  end
end
