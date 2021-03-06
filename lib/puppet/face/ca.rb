require 'puppet/face'
require 'puppet/util/password_utils'
require 'puppet/ssl/ca_password'

Puppet::Face.define(:ca, '0.1.0') do
  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  summary "Local Puppet Certificate Authority management."

  description <<-TEXT
    This provides local management of the Puppet Certificate Authority.

    You can use this subcommand to sign outstanding certificate requests, list
    and manage local certificates, and inspect the state of the CA.

    If the configuration parameter ca_explicitpassword=true, then the user will prompted for a password for the 
    CA private key when invoking generate or sign. The first invocation will create the CA private key, encrypted
    using the entered password. Subsequent invocations will use the password to encrypt the private key and sign the certificate. 
    
  TEXT

  action :list do
    summary "List certificates and/or certificate requests."

    description <<-TEXT
      This will list the current certificates and certificate signing requests
      in the Puppet CA.  You will also get the fingerprint, and any certificate
      verification failure reported.
    TEXT

    option "--[no-]all" do
      summary "Include all certificates and requests."
    end

    option "--[no-]pending" do
      summary "Include pending certificate signing requests."
    end

    option "--[no-]signed" do
      summary "Include signed certificates."
    end

    option "--subject PATTERN" do
      summary "Only list if the subject matches PATTERN."

      description <<-TEXT
        Only include certificates or requests where subject matches PATTERN.

        PATTERN is interpreted as a regular expression, allowing complex
        filtering of the content.
      TEXT
    end

    when_invoked do |options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false      
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      pattern = options[:subject].nil? ? nil :
        Regexp.new(options[:subject], Regexp::IGNORECASE)

      pending = options[:pending].nil? ? options[:all] : options[:pending]
      signed  = options[:signed].nil?  ? options[:all] : options[:signed]

      # By default we list pending, so if nothing at all was requested...
      unless pending or signed then pending = true end

      hosts = []

      pending and hosts += ca.waiting?
      signed  and hosts += ca.list

      pattern and hosts = hosts.select {|hostname| pattern.match hostname }

      hosts.sort.map {|host| Puppet::SSL::Host.new(host) }
    end

    when_rendering :console do |hosts|
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      length = hosts.map{|x| x.name.length }.max.to_i + 1

      hosts.map do |host|
        name = host.name.ljust(length)
        if host.certificate_request then
          "  #{name} (#{host.certificate_request.fingerprint})"
        else
          begin
            ca.verify(host.name)
            "+ #{name} (#{host.certificate.fingerprint})"
          rescue Puppet::SSL::CertificateAuthority::CertificateVerificationError => e
            "- #{name} (#{host.certificate.fingerprint}) (#{e.to_s})"
          end
        end
      end.join("\n")
    end
  end

  action :destroy do
    when_invoked do |host, options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false      
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      ca.destroy host
    end
  end

  action :revoke do
    when_invoked do |host, options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false      
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      begin
        ca.revoke host
      rescue ArgumentError => e
        # This is a bit naff, but it makes the behaviour consistent with the
        # destroy action.  The underlying tools could be nicer for that sort
        # of thing; they have fairly inconsistent reporting of failures.
        raise unless e.to_s =~ /Could not find a serial number for /
        "Nothing was revoked"
      end
    end
  end

  action :generate do
    option "--dns-alt-names NAMES" do
      summary "Additional DNS names to add to the certificate request"
      description Puppet.settings.setting(:dns_alt_names).desc
    end

    when_invoked do |host, options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      begin
        ca.generate(host, :dns_alt_names => options[:dns_alt_names])
      rescue RuntimeError => e
        if e.to_s =~ /already has a requested certificate/
          "#{host} already has a certificate request; use sign instead"
        else
          raise
        end
      rescue ArgumentError => e
        if e.to_s =~ /A Certificate already exists for /
          "#{host} already has a certificate"
        else
          raise
        end
      end
    end
  end

  action :sign do
    option("--[no-]allow-dns-alt-names") do
      summary "Whether or not to accept DNS alt names in the certificate request"
    end

    when_invoked do |host, options|     
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      begin
        ca.sign(host, options[:allow_dns_alt_names])
      rescue ArgumentError => e
        if e.to_s =~ /Could not find certificate request/
          e.to_s
        else
          raise
        end
      end
    end
  end

  action :print do
    when_invoked do |host, options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false      
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      ca.print host
    end
  end

  action :fingerprint do
    option "--digest ALGORITHM" do
      summary "The hash algorithm to use when displaying the fingerprint"
    end

    when_invoked do |host, options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false      
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      begin
        # I want the default from the CA, not to duplicate it, but passing
        # 'nil' explicitly means that we don't get that.  This works...
        if options.has_key? :digest
          ca.fingerprint host, options[:digest]
        else
          ca.fingerprint host
        end
      rescue ArgumentError => e
        raise unless e.to_s =~ /Could not find a certificate or csr for/
        nil
      end
    end
  end

  action :verify do
    when_invoked do |host, options|
      raise "Not a CA" unless Puppet::SSL::CertificateAuthority.ca?
      Puppet::SSL::Ca_password.password = Puppet::Util::Password_utils.capturepassword unless Puppet.settings[ :ca_explicitpassword] == false      
      unless ca = Puppet::SSL::CertificateAuthority.instance
        raise "Unable to fetch the CA"
      end

      begin
        ca.verify host
        { :host => host, :valid => true }
      rescue ArgumentError => e
        raise unless e.to_s =~ /Could not find a certificate for/
        { :host => host, :valid => false, :error => e.to_s }
      rescue Puppet::SSL::CertificateAuthority::CertificateVerificationError => e
        { :host => host, :valid => false, :error => e.to_s }
      end
    end

    when_rendering :console do |value|
      if value[:valid]
        nil
      else
        "Could not verify #{value[:host]}: #{value[:error]}"
      end
    end
  end
end
