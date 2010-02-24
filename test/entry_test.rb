#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Config
	class FilenameTest <Test::Unit::TestCase
		include TestHelper

		def test_entries
			with_testdir do |dir|
				# Create the source directory
				dir.join("source").mkdir

				# Create some files/directories
				dir.join("source", "_foo").touch
				dir.join("source", "_bar").mkdir
				dir.join("source", "_bar", "baz").touch

				# Create the base (also creates the target directory)
				base=Base.new("#{dir}/source", "#{dir}/build", "#{dir}/target", "#{dir}/backup")
				entries=base.entries

				# Extract the entries by name and make sure they are found
				foo=entries.find { |entry| entry.path.to_s=="_foo" }
				bar=entries.find { |entry| entry.path.to_s=="_bar" }
				baz=entries.find { |entry| entry.path.to_s=="_bar/baz" }

				assert_not_nil foo
				assert_not_nil bar
				assert_not_nil baz

				# Sort the entries: dependent entries after prerequisites
				# (e. g. files after the directory they're in)
				entries=[foo, bar, baz]

				# The path names must be absolute and correct
				assert baz.source.absolute?
				assert baz.build .absolute?
				assert baz.target.absolute?
				assert baz.backup.absolute?

				assert_equal dir.join("source", "_bar", "baz").absolute, baz.source
				assert_equal dir.join("build" , "_bar", "baz").absolute, baz.build
				assert_equal dir.join("target", ".bar", "baz").absolute, baz.target
				assert_equal dir.join("backup", ".bar", "baz").absolute, baz.backup

				# directory? must return the correct value
				assert_equal false, foo.directory?
				assert_equal true , bar.directory?
				assert_equal false, baz.directory?

				# link_target must return the correct relative link
				assert_equal    "../build/_foo"    , foo.link_target.to_s
				assert_equal    "../build/_bar"    , bar.link_target.to_s
				assert_equal "../../build/_bar/baz", baz.link_target.to_s

				# The target may not exist at this point
				assert_not_exist foo.target

				# Test target_exist?, target_directory?, target_current?
				# Not existing
				assert_equal false, foo.target_exist?
				assert_equal false, foo.target_directory?
				assert_equal false, foo.target_current?

				# Test target_exist?, target_directory?, target_current?
				# File
				foo.target.touch
				assert_equal true , foo.target_exist?
				assert_equal false, foo.target_directory?
				assert_equal false, foo.target_current?
				foo.target.delete

				# Test target_exist?, target_directory?, target_current?
				# Directory
				foo.target.mkdir
				assert_equal true , foo.target_exist?
				assert_equal true , foo.target_directory?
				assert_equal false, foo.target_current?
				foo.target.delete

				# Test target_exist?, target_directory?, target_current?
				# Symlink to file (not current)
				foo.target.make_symlink "../source/_bar/baz"
				assert_equal true , foo.target_exist?
				assert_equal false, foo.target_directory?
				assert_equal false, foo.target_current?
				foo.target.delete

				# Test target_exist?, target_directory?, target_current?
				# Symlink to directory (not current)
				foo.target.make_symlink "../source/_bar"
				assert_equal true , foo.target_exist?
				assert_equal false, foo.target_directory?
				assert_equal false, foo.target_current?
				foo.target.delete

				# Test target_current? - Not existing
				assert_equal false, foo.target_current?
				assert_equal false, bar.target_current?
				assert_equal false, baz.target_current?

				entries.each do |entry|
					# create! must create the target

					# Test create! with existing target - Directory
					entry.target.mkdir;
					assert_raise(RuntimeError) { entry.create! }
					entry.target.delete

					# Test create! with existing target - File
					entry.target.touch
					assert_raise(RuntimeError) { entry.create! }
					entry.target.delete

					# Test create! (success)
					assert_nothing_raised { entry.create! }
					assert_exist entry.target
					assert       entry.target_exist?
					assert       entry.target_current?
				end

				# Basic backup - file
				assert_exist     dir.join "target/.foo"
				assert_not_exist dir.join "backup/.foo"
				foo.remove!
				assert_not_exist dir.join "target/.foo"
				assert_exist     dir.join "backup/.foo"

				# Basic backup - directory
				assert_exist     dir.join "target/.bar"
				assert_exist     dir.join "target/.bar/baz"
				assert_not_exist dir.join "backup/.bar"
				bar.remove!
				assert_not_exist dir.join "target/.bar"
				assert_exist     dir.join "backup/.bar"
				assert_exist     dir.join "backup/.bar/baz"

				# Undo the last backup
				bar.backup.rename bar.target
				assert_exist     dir.join "target/.bar"
				assert_exist     dir.join "target/.bar/baz"
				assert_not_exist dir.join "backup/.bar"

				# Remove file in directory although backup directory does not
				# exist
				assert_exist     dir.join "target/.bar/baz"
				assert_not_exist dir.join "backup/.bar/baz"
				baz.remove!
				assert_not_exist dir.join "target/.bar/baz"
				assert_exist     dir.join "backup/.bar/baz"

				# Remove directory with files although backup directory
				# already exists
				bar.target.join("bull").touch
				bar.target.join(".bull").touch
				assert_exist     dir.join "target/.bar"
				assert_exist     dir.join "target/.bar/bull"
				assert_exist     dir.join "target/.bar/.bull"
				assert_exist     dir.join "backup/.bar"
				bar.remove!
				assert_not_exist dir.join "target/.bar"
				assert_exist     dir.join "backup/.bar"
				assert_exist     dir.join "backup/.bar/bull"
				assert_exist     dir.join "backup/.bar/.bull"

				# Basic building
				assert_not_exist dir.join "build/_foo"
				assert !foo.built?
				foo.build!
				assert_exist     dir.join "build/_foo"
				assert foo.built?

				# Build current
				assert foo.build_current?
				foo.build.utime(foo.source.mtime-1, foo.source.mtime-1)
				assert !foo.build_current?
				foo.build!
				assert foo.build_current?
				foo.build.delete
				assert !foo.build_current?

				# Building a directory
				assert_not_exist dir.join "build/_bar"
				bar.build!
				assert_directory dir.join "build/_bar"

				# Remove it
				dir.join("build/_bar").rmdir

				# Building a file in a non-existing directory
				assert_not_exist dir.join "build/_bar"
				baz.build!
				assert_directory dir.join "build/_bar"
				assert_exist     dir.join "build/_bar/baz"
			end

			# TODO test install!(overwrite)
		end

		def test_full
			with_testdir do |dir|
				# Create the source data
				dir.join("source").mkdir
				dir.join("source", "_foo").touch
				dir.join("source", "_bar").mkdir
				dir.join("source", "_bar", "baz").touch

				# Create the expected target data
				dir.join("expected", "target").mkpath
				dir.join("expected", "target", ".foo").make_symlink("../build/_foo")
				dir.join("expected", "target", ".bar").mkdir
				dir.join("expected", "target", ".bar", "baz").make_symlink("../../build/_bar/baz")

				# Create the expected build data
				dir.join("expected", "build").mkpath
				dir.join("expected", "build", "_foo").touch
				dir.join("expected", "build", "_bar").mkdir
				dir.join("expected", "build", "_bar", "baz").touch

				expected=dir.join("expected").absolute
				actual  =dir.join("actual"  ).absolute

				# Create the base (also creates the target directory)
				base=Base.new("#{dir}/source", "#{dir}/actual/build", "#{dir}/actual/target", "#{dir}/backup")

				base.entries.each do |entry|
					entry.build!
					entry.install!(false)
				end

				assert_tree_equal(expected, actual)
				#p expected.tree_entries
			end
		end
	end
end

