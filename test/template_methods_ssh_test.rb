#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class TemplateMethodsSshTest <Test::Unit::TestCase
		include TemplateMethods::Ssh

		def test_parse_key
			# Plain key (with long comment)
			key=Key.new('ssh-dss AAAAB3Nz...fz8= deffi@aquilae (Zeta Aquilae)')
			assert_equal nil, key.options
			assert_equal "ssh-dss", key.type
			assert_equal "AAAAB3Nz...fz8=", key.key
			assert_equal "deffi@aquilae (Zeta Aquilae)", key.comment
			assert_equal "deffi@aquilae", key.name

			# Unknown key type
			assert_raise(ArgumentError) {
				key=Key.new('ssh-xyz AAAAB3Nz...fz8= deffi@quartzon')
			}

			# With options
			key=Key.new('from="acme.de",command="bin/bam" ssh-dss AAAAB3Nz...fz8= deffi@brimspark')
			assert_equal 'from="acme.de",command="bin/bam"', key.options
			assert_equal "ssh-dss", key.type
			assert_equal "AAAAB3Nz...fz8=", key.key
			assert_equal "deffi@brimspark", key.comment
			assert_equal "deffi@brimspark", key.name

			# With quoted space in command
			key=Key.new('command="ls /tmp" ssh-dss AAAAB3Nz...fz8= deffi@limefrost')
			assert_equal 'command="ls /tmp"', key.options
			assert_equal "ssh-dss", key.type
			assert_equal "AAAAB3Nz...fz8=", key.key
			assert_equal "deffi@limefrost", key.comment
			assert_equal "deffi@limefrost", key.name

			# With quoted quote in command
			key=Key.new('command="ls \"/tmp\"" ssh-dss AAAAB3Nz...fz8= deffi@baloris')
			assert_equal 'command="ls \"/tmp\""', key.options
			assert_equal "ssh-dss", key.type
			assert_equal "AAAAB3Nz...fz8=", key.key
			assert_equal "deffi@baloris", key.comment
			assert_equal "deffi@baloris", key.name

			# Without comment - must fail
			assert_raise(ArgumentError) {
				key=Key.new('ssh-dss AAAAB3Nz...fz8=')
			}

			# Puuma
			# Omega
			# Tycho
			# Brahe
		end

		def test_parse_keys
			keys=[
				"ssh-dss foo deffi@tycho",
				"ssh-dss bar deffi@brahe (omega)"
			]

			parsed=_parse_keys(keys)
			assert_equal "ssh-dss foo deffi@tycho"        , parsed['deffi@tycho'].complete
			assert_equal "ssh-dss bar deffi@brahe (omega)", parsed['deffi@brahe'].complete

		end
	end
end



