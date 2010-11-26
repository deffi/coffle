#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class ArrayExtensionsTest <Test::Unit::TestCase
		def test_fill_length
			a=[]

			b=a.fill_length(2, 42)
			assert_equal([42,42], b)
			assert_equal([], a)

			c=b.fill_length(5, 23)
			assert_equal([42,42,23,23,23], c)
			assert_equal([42,42], b)

			# Noop
			d=c.fill_length(4, 666)
			assert_equal([42,42,23,23,23], d)
			assert_equal([42,42,23,23,23], c)
		end

		def test_fill_length!
			a=[]
			assert_equal([], a)

			a.fill_length!(2, 42)
			assert_equal([42,42], a)

			a.fill_length!(5, 23)
			assert_equal([42,42,23,23,23], a)

			# Noop
			a.fill_length!(4, 666)
			assert_equal([42,42,23,23,23], a)
		end

		def test_format_table
			a=[
				["a", "bbb"],
				["cc", "d"]
			]

			expected="a  bbb\ncc d  "
			assert_equal(expected, a.format_table)

			expected="a ,bbb\ncc,d  "
			assert_equal(expected, a.format_table(","))

			expected="a    bbb\ncc   d  "
			assert_equal(expected, a.format_table("   "))
		end
	end
end


