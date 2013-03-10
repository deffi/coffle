#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class TemplateMethodsTest <Test::Unit::TestCase
		include TemplateMethods

		def test_username
			un=username

			assert_equal ENV['USER']    , un
			assert_equal `whoami`.chomp , un
			assert_equal Etc.getlogin   , un
		end
	end
end


