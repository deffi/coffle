#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class StringExtensionsTest <Test::Unit::TestCase
		def test_prefix_lines
			# Multi-character prefix
			assert_equal <<-expected.strip, (<<input).prefix_lines("// ").strip
// foo
// bar
expected
foo
bar
input

			# Single-character prefix
			assert_equal <<-expected.strip, (<<input).prefix_lines("# ").strip
# foo
# bar
expected
foo
bar
input
		end

		def test_wrap
			# Wrapping on blanks
			assert_equal <<expected.strip, (<<input).wrap(10).strip
foo bar
baz qux
expected
foo bar baz qux
input

			# Wrapping before slashes
			assert_equal <<expected.strip, (<<input).wrap(10).strip
foo/bar/
baz/qux
expected
foo/bar/baz/qux
input
		end
	end
end


