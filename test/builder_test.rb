#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

require 'coffle/pathname_extensions'

module Coffle
	class BuilderTest <Test::Unit::TestCase
		include TestHelper

		def test_build
			# ERB tags must be processed
			builder=Builder.new(nil)
			result=builder.process("2 + 3 = <%=1+4%>")
			assert_equal "2 + 3 = 5", result
			assert_equal false, builder.skipped?
		end

		def test_skip
			# When skip! is called, nil must be returned
			builder=Builder.new(nil)
			result=builder.process("foobar <% skip! %>")
			assert_equal nil, result
			assert_equal true, builder.skipped?
		end
	end
end

