#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class FilenameTest <Test::Unit::TestCase
		include Filenames

		def test_unescape_filename
			# Usually, files are passed through
			assert_equal "foo" , unescape_filename( "foo")
			assert_equal ".foo", unescape_filename(".foo")

			# _ and - in the filename are not touched
			assert_equal "f-oo", unescape_filename("f-oo")
			assert_equal "f_oo", unescape_filename("f_oo")

			# _ means dotfile, - means no dotfile
			assert_equal ".foo", unescape_filename("_foo")
			assert_equal "foo" , unescape_filename("-foo")

			# We can generate files and dotfiles beginning with _ and -
			assert_equal "_foo" , unescape_filename("-_foo")
			assert_equal "-foo" , unescape_filename("--foo")
			assert_equal "._foo", unescape_filename("__foo")
			assert_equal ".-foo", unescape_filename("_-foo")

			# We can generate files and dotfiles beginning with __ and --
			assert_equal "__foo" , unescape_filename("-__foo")
			assert_equal "--foo" , unescape_filename("---foo")
			assert_equal ".__foo", unescape_filename("___foo")
			assert_equal ".--foo", unescape_filename("_--foo")

			# We can generate files and dotfiles beginning with _- and -_
			assert_equal "_-foo" , unescape_filename("-_-foo")
			assert_equal "-_foo" , unescape_filename("--_foo")
			assert_equal "._-foo", unescape_filename("__-foo")
			assert_equal ".-_foo", unescape_filename("_-_foo")
		end

		def test_unescape_path
			# Regular
			assert_equal "foo/bar", unescape_path("foo/bar")

			# Dotfiles
			assert_equal "foo/bar"  , unescape_path("foo/bar"  )
			assert_equal "foo/.bar" , unescape_path("foo/_bar" )
			assert_equal ".foo/bar" , unescape_path("_foo/bar" )
			assert_equal ".foo/.bar", unescape_path("_foo/_bar")

			# Non-dotfiles
			assert_equal "foo/bar", unescape_path("foo/-bar" )
			assert_equal "foo/bar", unescape_path("-foo/bar" )
			assert_equal "foo/bar", unescape_path("-foo/-bar")

			# With dots
			assert_equal "foo/.bar/baz", unescape_path("foo/.bar/baz" )

			# Pathnames
			assert_equal Pathname.new(".foo/bar"), unescape_path(Pathname.new("_foo/-bar"))
		end
	end
end

