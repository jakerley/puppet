if __FILE__ == $0
    $:.unshift '..'
    $:.unshift '../../lib'
    $puppetbase = "../../../../language/trunk"
end

require 'puppet'
require 'test/unit'

# $Id$

class TestService < Test::Unit::TestCase
    # hmmm
    # this is complicated, because we store references to the created
    # objects in a central store
    def setup
        @sleeper = nil
        script = File.join($puppetbase,"examples/root/etc/init.d/sleeper")
        @status = script + " status"

        Puppet[:debug] = 1
        assert_nothing_raised() {
            unless Puppet::Type::Service.has_key?("sleeper")
                Puppet::Type::Service.new(
                    :name => "sleeper",
                    :running => 1
                )
                Puppet::Type::Service.setpath(
                    File.join($puppetbase,"examples/root/etc/init.d")
                )
            end
            @sleeper = Puppet::Type::Service["sleeper"]
        }
    end

    def test_process_start
        # start it
        assert_nothing_raised() {
            @sleeper[:running] = 1
        }
        assert_nothing_raised() {
            @sleeper.retrieve
        }
        assert(!@sleeper.insync?())
        assert_nothing_raised() {
            @sleeper.sync
        }
        assert_nothing_raised() {
            @sleeper.retrieve
        }
        assert(@sleeper.insync?)

        # test refreshing it
        assert_nothing_raised() {
            @sleeper.refresh
        }

        assert(@sleeper.respond_to?(:refresh))

        # now stop it
        assert_nothing_raised() {
            @sleeper[:running] = 0
        }
        assert_nothing_raised() {
            @sleeper.retrieve
        }
        assert(!@sleeper.insync?())
        assert_nothing_raised() {
            @sleeper.sync
        }
        assert_nothing_raised() {
            @sleeper.retrieve
        }
        assert(@sleeper.insync?)
    end
    def teardown
        Kernel.system("pkill sleeper")
    end
end
