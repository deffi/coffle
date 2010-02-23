#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Config
	class BaseTest <Test::Unit::TestCase
		include TestHelper

		def test_paths
			with_testdir do |dir|
				# If the source does not exist, an error must be raised
				assert_raise RuntimeError do
					Base.new("#{dir}/source", "#{dir}/target", "#{dir}/backup")
				end

				# Create the source directory
				dir.join("source").mkdir

				# Create the Base
				base=Base.new("#{dir}/source", "#{dir}/target", "#{dir}/backup")

				# The target directory must exist now
				assert_directory dir.join("target")

				# Absolute paths
				assert_equal "#{dir.realpath}/source", base.source.to_s
				assert_equal "#{dir.realpath}/target", base.target.to_s

				# Relative paths
				assert_equal "#{dir}/backup", base.backup.to_s

				# The backup direcory must not exist (only created when used)
				assert_not_exist base.backup
			end
		end

		def test_entries
			with_testdir do |dir|
				dir.join("source").mkdir

				dir.join("source", "_foo").touch
				dir.join("source", "_bar").mkdir
				dir.join("source", "_bar", "baz").touch
				dir.join("source", ".ignore").touch # Must be ignored

				base=Base.new("#{dir}/source", "#{dir}/target", "#{dir}/backup")
				entries=base.entries.map { |entry| entry.path.to_s }

				# The number of entries must be correct
				assert_equal 3, entries.size

				# Entry paths are relative to the source directory
				assert_include "_foo", entries
				assert_include "_bar", entries
				assert_include "_bar/baz", entries


				#dir.dump
			end
		end
	end
end

