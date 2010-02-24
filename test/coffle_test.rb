#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

require 'coffle/pathname_extensions'

module Coffle
	class CoffleTest <Test::Unit::TestCase
		include TestHelper

		def test_paths
			with_testdir do |dir|
				assert dir.relative?

				# If the source does not exist, an error must be raised
				assert_raise RuntimeError do
					Coffle.new("#{dir}/source", "#{dir}/build", "#{dir}/target", "#{dir}/backup")
				end

				# Create the source directory
				dir.join("source").mkdir

				# Create the Coffle
				coffle=Coffle.new("#{dir}/source", "#{dir}/build", "#{dir}/target", "#{dir}/backup")

				# The build and target directories must exist now
				assert_directory dir.join("build")
				assert_directory dir.join("target")

				# Absolute paths
				assert_equal "#{dir.absolute}/source", coffle.source.to_s
				assert_equal "#{dir.absolute}/build" , coffle.build .to_s
				assert_equal "#{dir.absolute}/target", coffle.target.to_s
				assert_equal "#{dir.absolute}/backup", coffle.backup.to_s

				# The backup direcory must not exist (only created when used)
				assert_not_exist coffle.backup
			end
		end

		def test_entries
			with_testdir do |dir|
				dir.join("source").mkdir

				dir.join("source", "_foo").touch
				dir.join("source", "_bar").mkdir
				dir.join("source", "_bar", "baz").touch
				dir.join("source", ".ignore").touch # Must be ignored

				# Construct with relative paths and strings
				coffle=Coffle.new("#{dir}/source", "#{dir}/build", "#{dir}/target", "#{dir}/backup")
				entries=coffle.entries.map { |entry| entry.path.to_s }

				# The number of entries must be correct
				assert_equal 3, entries.size

				# Entry paths are relative to the source directory
				assert_include "_foo", entries
				assert_include "_bar", entries
				assert_include "_bar/baz", entries
			end
		end
	end
end

