if __FILE__ == $0
    $:.unshift '..'
    $:.unshift '../../lib'
    $puppetbase = "../../../../language/trunk"
end

require 'puppet'
require 'test/unit'
require 'facter'

# $Id$

class TestPackagingType < Test::Unit::TestCase
    def test_listing
        platform = Facter["operatingsystem"].value
        type = nil
        case platform
        when "SunOS"
            type = "sunpkg"
        when "Linux"
            type = "dpkg"
        else
            type = :invalid
        end

        assert_nothing_raised() {
            Puppet::PackagingType[type].list
        }
    end
end

class TestPackageSource < Test::Unit::TestCase
    def test_filesource
        system("touch /tmp/fakepackage")
        assert_equal(
            "/tmp/fakepackage",
            Puppet::PackageSource.get("file:///tmp/fakepackage")
        )
        system("rm -f /tmp/fakepackage")
    end
end

class TestPackages < Test::Unit::TestCase
    def setup
        @list = Puppet::Type::Package.getpkglist
    end

    def teardown
        Puppet::Type::Package.clear
    end

    def test_checking
        pkg = nil
        assert_nothing_raised() {
            pkg = @list[rand(@list.length)]
        }
        assert(pkg)
        assert_nothing_raised() {
            pkg.evaluate
        }
        assert_nothing_raised() {
            pkg[:install] = pkg[:install]
        }
        assert_nothing_raised() {
            pkg.evaluate
        }
        assert_nothing_raised() {
            pkg[:install] = "1.2.3.4"
        }
        assert(!pkg.insync?)
    end
end
