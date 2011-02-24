#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

require 'coffle/pathname_extensions'

module Coffle
	class CoffleTest <Test::Unit::TestCase
		include TestHelper

		def test_coffle_directory
			with_testdir do |dir|
				source_dir=dir.join("source")
				target_dir=dir.join("target")

				# It does not exist
				assert_equal false, Coffle.coffle_source_directory?(source_dir)
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.assert_source_directory(source_dir) }
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.new(source_dir, target_dir) }

				# It's not a coffle source directory
				assert_equal false, Coffle.coffle_source_directory?(source_dir)
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.assert_source_directory(source_dir) }
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.new(source_dir, target_dir) }

				# Make it a coffle source directory
				Coffle.initialize_source_directory(source_dir)

				assert_equal true, Coffle.coffle_source_directory?(source_dir)
				assert_nothing_raised { Coffle.assert_source_directory(source_dir) }
				assert_nothing_raised { Coffle.new(source_dir, target_dir) }
			end
		end

		def test_paths
			with_testdir do |dir|
				assert dir.relative?

				# Create and initialize the source directory
				source_dir=dir.join("source")
				source_dir.mkdir
				Coffle.initialize_source_directory(source_dir)

				# Create the Coffle
				coffle=Coffle.new("#{dir}/source", "#{dir}/target")

				# The build and target directories must exist now
				assert_directory dir.join("source/.build")
				assert_directory dir.join("source/.build/.org")
				assert_directory dir.join("target")

				# Absolute paths
				assert_equal "#{dir.absolute}/source"             , coffle.source.to_s
				assert_equal "#{dir.absolute}/source/.build"      , coffle.build .to_s
				assert_equal "#{dir.absolute}/source/.build/.org" , coffle.org   .to_s
				assert_equal "#{dir.absolute}/source/.backup"     , coffle.backup.to_s
				assert_equal "#{dir.absolute}/target"             , coffle.target.to_s
				#assert_match /^#{dir.absolute}\/source\/.backups\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d$/,
				#	                                                coffle.backup.to_s

				# The backup direcory must not exist (only created when used)
				assert_not_present coffle.backup
			end
		end

		def test_entries
			with_testdir do |dir|
				source_dir=dir.join("source")

				source_dir.mkdir
				Coffle.initialize_source_directory(source_dir)

				source_dir.join("_foo").touch
				source_dir.join("_bar").mkdir
				source_dir.join("_bar", "baz").touch
				source_dir.join(".ignore").touch # Must be ignored

				# Construct with relative paths and strings
				coffle=Coffle.new("#{dir}/source", "#{dir}/target")
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

