#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class FilenameTest <Test::Unit::TestCase
		include TestHelper

		# Create some test data in a test directory.
		# The directory name will be passed to the block.
		#
		# Paths (relative to dir):
		# * source: .source/
		# * build:  .build/
		# * org:    .build/.org
		# * target: .target/
		# * backup: .backup/
		#
		# Test entries:
		# * file      _foo
		# * directory _bar
		# * file      _bar/baz
		#
		def with_test_data
			with_testdir do |dir|
				# Create the source directory
				dir.join("source").mkdir

				# Create some files/directories
				dir.join("source", "_foo").write("Foo")
				dir.join("source", "_bar").mkdir
				dir.join("source", "_bar", "baz").write("Baz")

				# Create the coffle (also creates the target directory)
				coffle=Coffle.new("#{dir}/source", "#{dir}/target")
				entries=coffle.entries

				# Extract the entries by name and make sure they are found
				@foo=entries.find { |entry| entry.path.to_s=="_foo" }
				@bar=entries.find { |entry| entry.path.to_s=="_bar" }
				@baz=entries.find { |entry| entry.path.to_s=="_bar/baz" }

				assert_not_nil @foo
				assert_not_nil @bar
				assert_not_nil @baz

				# Sort the entries: contained entries after containing entries
				# (e. g. files after the directory they're in)
				entries=[@foo, @bar, @baz]

				yield dir, entries

				# Don't test the reverse order, because some of the tests
				# require that the file does not exist before the test and
				# creating a file also creates the directory it is in.

				# TODO test for individual entries (yield dir, [@baz]), but
				# have to restore state first
			end
		end

		def test_paths
			with_test_data do |dir, entries|
				# The path names must be absolute
				entries.each do |entry|
					assert entry.source.absolute?
					assert entry.build .absolute?
					assert entry.target.absolute?
					assert entry.backup.absolute?
				end

				# The path names must have the correct values
				assert_equal dir.join("source"                    , "_foo").absolute, @foo.source
				assert_equal dir.join("source", ".build"          , "_foo").absolute, @foo.build
				assert_equal dir.join("source", ".build" , ".org" , "_foo").absolute, @foo.org
				assert_equal dir.join("target"                    , ".foo").absolute, @foo.target
				assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.foo$/,
					                                                                  @foo.backup.to_s

				assert_equal dir.join("source"                    , "_bar").absolute, @bar.source
				assert_equal dir.join("source", ".build"          , "_bar").absolute, @bar.build
				assert_equal dir.join("source", ".build", ".org"  , "_bar").absolute, @bar.org
				assert_equal dir.join("target"                    , ".bar").absolute, @bar.target
				assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.bar$/,
					                                                                  @bar.backup.to_s

				assert_equal dir.join("source"                    , "_bar", "baz").absolute, @baz.source
				assert_equal dir.join("source", ".build"          , "_bar", "baz").absolute, @baz.build
				assert_equal dir.join("source", ".build", ".org"  , "_bar", "baz").absolute, @baz.org
				assert_equal dir.join("target"                    , ".bar", "baz").absolute, @baz.target
				assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.bar\/baz$/,
					                                                                         @baz.backup.to_s
			end
		end

		def test_directory
			with_test_data do |dir, entries|
				# directory? must return true for directory entries, false for
				# file entries
				assert_equal false, @foo.directory?
				assert_equal true , @bar.directory?
				assert_equal false, @baz.directory?
			end
		end

		def test_link_target
			with_test_data do |dir, entries|
				# link_target must return a relative link to the build path
				assert_equal    "../source/.build/_foo"    , @foo.link_target.to_s
				assert_equal    "../source/.build/_bar"    , @bar.link_target.to_s
				assert_equal "../../source/.build/_bar/baz", @baz.link_target.to_s
			end
		end

		def test_target_checks
			with_test_data do |dir, entries|
				entries.each do |entry|
					# The target may not exist (not created yet)
					assert_not_exist entry.target

					# If the target does not exist, target_exist?,
					# target_directory? and installed? must return false
					assert_equal false, entry.target_exist?
					assert_equal false, entry.target_directory?
					assert_equal false, entry.installed?

					# If the target is a file, target_exist? must return true,
					# target_directory? and installed? must return false
					entry.target.dirname.mkpath
					entry.target.touch
					assert_equal true , entry.target_exist?
					assert_equal false, entry.target_directory?
					assert_equal false, entry.installed?
					entry.target.delete

					# If the target is a directory, target_exist? and
					# target_directory? must return true, installed? must
					# return true exactly for directory entries
					entry.target.mkdir
					assert_equal true            , entry.target_exist?
					assert_equal true            , entry.target_directory?
					assert_equal entry.directory?, entry.installed?
					entry.target.delete

					# If the target is a symlink to a non-existing file,
					# target_exist? must return true, target_directory?
					# and installed? must return false
					entry.target.make_symlink "bull"
					assert_equal true , entry.target_exist?
					assert_equal false, entry.target_directory?
					assert_equal false, entry.installed?
					entry.target.delete

					# If the target is a symlink to a file (except the correct
					# link target), target_exist? must return true,
					# target_directory? and installed? must return false
					entry.target.dirname.join("dummy").touch
					entry.target.make_symlink "dummy"
					assert_equal true , entry.target_exist?
					assert_equal false, entry.target_directory?
					assert_equal false, entry.installed?
					entry.target.delete
					entry.target.dirname.join("dummy").delete

					# If the target is a symlink to a directory, target_exist?
					# must return true, target_directory? and installed?
					# must return false.
					entry.target.make_symlink "."
					assert_equal true , entry.target_exist?
					assert_equal false, entry.target_directory?
					assert_equal false, entry.installed?
					entry.target.delete
				end
			end
		end

		def test_create
			with_test_data do |dir, entries|
				entries.each do |entry|
					# If the target already exists and is a directory, create! must
					# raise an exception
					entry.target.mkpath
					assert_raise(RuntimeError) { entry.create! }
					entry.target.rmdir

					# If the target already exists and is a file, create! must
					# raise an exception
					entry.target.dirname.mkpath
					entry.target.touch
					assert_raise(RuntimeError) { entry.create! }
					entry.target.delete

					# If the target does not exist, create! must succeed, the
					# target must exist and be current, and be a directory exactly
					# for directory entries
					assert_nothing_raised { entry.create! }
					assert_exist entry.target
					assert       entry.target_exist?
					assert       entry.installed?
					assert_equal entry.directory?, entry.target_directory?
				end
			end
		end

		def test_remove
			with_test_data do |dir, entries|
				entries.each do |entry|
					# Create the entry
					entry.create!

					# The target must exist, the backup may not exist
					assert_exist     entry.target
					assert_not_exist entry.backup

					# Remove the entry (creates a backup)
					entry.remove!
					
					# The target may not exist, the backup must exist
					assert_not_exist entry.target
					assert_exist     entry.backup
				end
			end
		end

		def test_remove_directory
			with_test_data do |dir, entries|
				# Create an entry in a subdirectory
				@baz.create!

				# Both the target for this entry and for the containing
				# directory must exist; the backups may not exist
				assert_exist @bar.target
				assert_exist @baz.target

				assert_not_exist @bar.backup
				assert_not_exist @baz.backup

				# Remove the containing directory
				@bar.remove!

				# The targets may not exist; the backups must exist
				assert_not_exist @bar.target
				assert_not_exist @baz.target

				assert_exist @bar.backup
				assert_exist @baz.backup
			end
		end

		def test_remove_file_from_directory
			with_test_data do |dir, entries|
				# Create an entry in a subdirectory
				@baz.create!

				# The backup directory for the containing entry may not exist
				assert_not_exist @bar.backup

				# Remove the entry in the subdirectory
				@baz.remove!

				# Now both the backup entry for the directory and for the entry
				# must exist.
				assert_exist @bar.backup
				assert_exist @baz.backup

				# The entry must not exist any more, the directory must still exist
				assert_exist     @bar.target
				assert_not_exist @baz.target
			end
		end

		def test_remove_directory_existing_backup
			with_test_data do |dir, entries|
				# Create and remove a directory entry with an additional file,
				# so the backup directory exists.
				@bar.create!
				@bar.target.join("previous").touch
				@bar.remove!

				# Recreate the directory entry and create a file and a dot file
				# in the directory
				@bar.create!
				@bar.target.join("bull").touch
				@bar.target.join(".bull").touch

				# Make sure the directory, the files and the backup directory exist
				assert_exist dir.join @bar.target
				assert_exist dir.join @bar.target.join("bull")
				assert_exist dir.join @bar.target.join(".bull")
				assert_exist dir.join @bar.backup

				# Remove the directory
				@bar.remove!

				# Make sure the directory does not exist any more and the files
				# exist in the backup directory.
				assert_not_exist @bar.target
				assert_exist     @bar.backup
				assert_exist     @bar.backup.join("bull")
				assert_exist     @bar.backup.join(".bull")
				assert_exist     @bar.backup.join("previous")
			end
		end

		def test_build
			with_test_data do |dir, entries|
				entries.each do |entry|
					# Before building, the build and org items may not exist
					assert_not_exist entry.build
					assert_not_exist entry.org
					assert !entry.built?

					# After building, the build and org items must exist and be identical
					entry.build!
					assert_exist entry.build
					assert_exist entry.org
					assert entry.built?

					if entry.directory?
						assert_tree_equal(entry.build, entry.org)
					else
						assert_file_equal(entry.build, entry.org)
					end

					# For directory entries, the built file must be a directory
					if entry.directory?
						assert_directory entry.build
						assert_directory entry.org
					else
						assert_file entry.build
						assert_file entry.org
					end
				end
			end
		end

		def test_build_outdated
			with_test_data do |dir, entries|
				# Test rebuilding of outdated entries, this only applies to
				# file entries
				entries.each do |entry|
					if !entry.directory?
						# Build - must be current
						entry.build!
						assert !entry.outdated?

						# Outdate - must be outdated
						entry.build.set_older(entry.source)
						assert entry.outdated?

						# Rebuild - must be current
						entry.build!
						assert !entry.outdated?
					end
				end
			end
		end

		def test_build_modified
			with_test_data do |dir, entries|
				# Test rebuilding of outdated entries, this only applies to
				# file entries
				entries.each do |entry|
					if !entry.directory?
						# Build - must be current
						entry.build!
						assert !entry.outdated?

						# Outdate and modify - must be outdated
						entry.build.append "x"
						entry.build.set_older(entry.source)
						assert entry.outdated?
						assert entry.modified?

						# Rebuild - must still be outdated because modified
						# entries are not overwritten
						entry.build!
						assert entry.outdated?

						# Rebuild with overwrite - must be current
						entry.build!(false, true)
						assert !entry.outdated?
					end
				end
			end
		end

		def test_outdated
			with_test_data do |dir, entries|
				entries.each do |entry|
					# Before building, the build must be outdated (it does
					# not exist)
					assert entry.outdated?

					# After building, the build must not be outdated
					entry.build!
					assert !entry.outdated?

					# If the build file is older than the source file,
					# outdated? must return true, except for directores,
					# which are never outdated
					entry.build.set_older(entry.source)
					assert  entry.outdated?                                     if !entry.directory?
					assert !entry.outdated?, "A directory must not be outdated" if  entry.directory?

					# After building, outdated? must return false again
					entry.build!
					assert !entry.outdated?
				end
			end
		end

		def test_modified
			with_test_data do |dir, entries|
				entries.each do |entry|
					entry.build!

					if entry.directory?
						assert_equal false, entry.modified?
					else
						assert_equal false, entry.modified?

						entry.build.append "x"
						assert_equal true, entry.modified?
					end
				end
			end
		end


		def test_build_file_in_nonexistent_directory
			with_test_data do |dir, entries|
				# Building a file in a non-existing directory
				assert_not_exist @bar.build
				assert_not_exist @bar.org
				@baz.build!
				assert_directory @bar.build
				assert_directory @bar.org
				assert_exist     @baz.build
				assert_exist     @baz.org
			end
		end

		# TODO test install!(overwrite)

		# TODO also compare file contents
		def test_full
			with_testdir do |dir|
				# source          in actual/source
				# target          in actual/target
				# expected source in expected/source (containing .build)
				# expected target in expected/target
				expected=dir.join("expected").absolute
				actual  =dir.join("actual"  ).absolute

				# Create the source data (and expected source)
				["actual", "expected"].each do |prefix|
					dir.join(prefix, "source").mkpath
					dir.join(prefix, "source", "_foo").touch
					dir.join(prefix, "source", "_bar").mkdir
					dir.join(prefix, "source", "_bar", "baz").touch
				end

				# Create the expected target data
				expected.join("target").mkpath
				expected.join("target", ".foo").make_symlink("../source/.build/_foo")
				expected.join("target", ".bar").mkdir
				expected.join("target", ".bar", "baz").make_symlink("../../source/.build/_bar/baz")

				# Create the expected build data
				expected.join("source", ".build").mkpath
				expected.join("source", ".build", "_foo").touch
				expected.join("source", ".build", "_bar").mkdir
				expected.join("source", ".build", "_bar", "baz").touch

				# Create the expected org data
				expected.join("source", ".build", ".org").mkpath
				expected.join("source", ".build", ".org", "_foo").touch
				expected.join("source", ".build", ".org", "_bar").mkdir
				expected.join("source", ".build", ".org", "_bar", "baz").touch

				# Create the coffle (also creates the build and target directories)
				coffle=Coffle.new("#{dir}/actual/source", "#{dir}/actual/target")

				coffle.entries.each do |entry|
					entry.build!
					entry.install!(false)
				end

				assert_tree_equal(expected, actual)
				#p expected.tree_entries
			end
		end
	end
end

