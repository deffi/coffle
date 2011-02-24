#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class FilenameTest <Test::Unit::TestCase
		include TestHelper

		# Create some test data in a test directory {{{
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
		# Also sets @foo, @bar, @baz (TODO pass a hash instead)
		#
		# Use with_test_entries instead if you do not need the dir or
		# the entries array }}}
		def with_test_data #{{{
			with_testdir do |dir|
				source_dir=dir.join("source")
				target_dir=dir.join("target")

				# Create and initialize the source directory
				source_dir.mkdir
				Coffle.initialize_source_directory(source_dir)

				# Create some files/directories
				source_dir.join("_foo").write("Foo")
				source_dir.join("_bar").mkdir
				source_dir.join("_bar", "baz").write("Baz")

				# Create the coffle (also creates the target directory)
				coffle=Coffle.new(source_dir, target_dir)
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
		end #}}}

		# Like with_test_data, but only passes each of the entries. {{{
		# Also, entries can be pre-filtered by type.
		# Use this rather than with_test_data if you don't need the directory,
		# the entries array or the individual entries by name. }}}
		def with_test_entries(selection=:all) #{{{
			with_test_data do |dir, entries|
				active_entries=
					case selection
					when :all         then entries
					when :files       then entries.select { |e| e.file? }
					when :directories then entries.select { |e| e.directory? }
					else raise ArgumentError, "Invalid selection #{selection.inspect}"
					end

				active_entries.each do |entry|
					yield entry
				end
			end
		end #}}}



		def test_paths #{{{
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
				assert_equal dir.join("source", ".backup"         , ".foo").absolute, @foo.backup
				assert_equal dir.join("target"                    , ".foo").absolute, @foo.target
				#assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.foo$/,
				#	                                                                  @foo.backup.to_s

				assert_equal dir.join("source"                    , "_bar").absolute, @bar.source
				assert_equal dir.join("source", ".build"          , "_bar").absolute, @bar.build
				assert_equal dir.join("source", ".build", ".org"  , "_bar").absolute, @bar.org
				assert_equal dir.join("source", ".backup"         , ".bar").absolute, @bar.backup
				assert_equal dir.join("target"                    , ".bar").absolute, @bar.target
				#assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.bar$/,
				#	                                                                  @bar.backup.to_s

				assert_equal dir.join("source"                    , "_bar", "baz").absolute, @baz.source
				assert_equal dir.join("source", ".build"          , "_bar", "baz").absolute, @baz.build
				assert_equal dir.join("source", ".build", ".org"  , "_bar", "baz").absolute, @baz.org
				assert_equal dir.join("source", ".backup"         , ".bar", "baz").absolute, @baz.backup
				assert_equal dir.join("target"                    , ".bar", "baz").absolute, @baz.target
				#assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.bar\/baz$/,
				#	                                                                         @baz.backup.to_s
			end
		end #}}}

		def test_with_test_entries #{{{
			# Make sure the with_test_entries selection works properly

			with_test_entries(:directories) do |entry|
				assert_equal true , entry.directory?
				assert_equal false, entry.file?
			end

			with_test_entries(:files) do |entry|
				assert_equal true , entry.file?
				assert_equal false, entry.directory?
			end
		end #}}}

		def test_directory #{{{
			with_test_data do |dir, entries|
				# directory? must return true for directory entries, false for
				# file entries
				assert_equal false, @foo.directory?
				assert_equal true , @bar.directory?
				assert_equal false, @baz.directory?
			end
		end #}}}

		def test_file #{{{
			with_test_data do |dir, entries|
				# file? must return false for directory entries, true for
				# file entries
				assert_equal true , @foo.file?
				assert_equal false, @bar.file?
				assert_equal true , @baz.file?
			end
		end #}}}

		def test_link_target #{{{
			with_test_data do |dir, entries|
				# link_target must return a relative link to the build path
				assert_equal    "../source/.build/_foo"    , @foo.link_target.to_s
				assert_equal    "../source/.build/_bar"    , @bar.link_target.to_s
				assert_equal "../../source/.build/_bar/baz", @baz.link_target.to_s
			end
		end #}}}

		def test_target_checks #{{{
			with_test_entries do |entry|
				# The target may not exist (not created yet)
				assert_not_exist entry.target

				# If the target does not exist, target.present?,
				# target_directory? and installed? must return false
				assert_equal false, entry.target.present?
				assert_equal false, entry.target_directory?
				assert_equal false, entry.installed?

				# If the target is a file, target.present? must return true,
				# target_directory? and installed? must return false
				entry.target.dirname.mkpath
				entry.target.touch
				assert_equal true , entry.target.present?
				assert_equal false, entry.target_directory?
				assert_equal false, entry.installed?
				entry.target.delete

				# If the target is a directory, target.present? and
				# target_directory? must return true, installed? must
				# return true exactly for directory entries
				entry.target.mkdir
				assert_equal true            , entry.target.present?
				assert_equal true            , entry.target_directory?
				assert_equal entry.directory?, entry.installed?
				entry.target.delete

				# If the target is a symlink to a non-existing file,
				# target.present? must return true, target_directory?
				# and installed? must return false
				entry.target.make_symlink "bull"
				assert_equal true , entry.target.present?
				assert_equal false, entry.target_directory?
				assert_equal false, entry.installed?
				entry.target.delete

				# If the target is a symlink to a file (except the correct
				# link target), target.present? must return true,
				# target_directory? and installed? must return false
				entry.target.dirname.join("dummy").touch
				entry.target.make_symlink "dummy"
				assert_equal true , entry.target.present?
				assert_equal false, entry.target_directory?
				assert_equal false, entry.installed?
				entry.target.delete
				entry.target.dirname.join("dummy").delete

				# If the target is a symlink to a directory, target.present?
				# must return true, target_directory? and installed?
				# must return false.
				entry.target.make_symlink "."
				assert_equal true , entry.target.present?
				assert_equal false, entry.target_directory?
				assert_equal false, entry.installed?
				entry.target.delete
			end
		end #}}}

		def test_create #{{{
			with_test_entries do |entry|
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
				assert       entry.target.present?
				assert       entry.installed?
				assert_equal entry.directory?, entry.target_directory?
			end
		end #}}}

		def test_remove #{{{
			with_test_entries do |entry|
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
		end #}}}

		def test_remove_directory #{{{
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
		end #}}}

		def test_remove_file_from_directory #{{{
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
		end #}}}

		def test_remove_directory_existing_backup #{{{
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
		end #}}}

		def test_build #{{{
			with_test_entries do |entry|
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
		end #}}}

		def test_build_outdated #{{{
			# Test rebuilding of outdated entries, this only applies to
			# file entries
			with_test_entries(:files) do |entry|
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
		end #}}}

		def test_build_modified #{{{
			# Test rebuilding of outdated entries, this only applies to
			# file entries
			with_test_entries(:files) do |entry|
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

				# Modify only
				entry.build.append "x"
				assert !entry.outdated?
				assert entry.modified?

				# Rebuild with overwrite - must no longer be modified,
				# even though it was current before
				assert !entry.outdated?
				entry.build!(false, true)
				assert !entry.outdated?
				assert !entry.modified?
			end
		end #}}}

		def test_outdated #{{{
			with_test_entries do |entry|
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
		end #}}}

		def test_modified #{{{
			with_test_entries do |entry|
				entry.build!

				if entry.directory?
					assert_equal false, entry.modified?
				else
					assert_equal false, entry.modified?

					entry.build.append "x"
					assert_equal true, entry.modified?
				end
			end
		end #}}}

		def test_build_file_in_nonexistent_directory #{{{
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
		end #}}}

		def test_matches? #{{{
			with_test_data do |dir, entries|
				dummy_dir=dir.join(".dummy")
				dummy_file     =dummy_dir.join("file")
				dummy_directory=dummy_dir.join("directory")
				dummy_none     =dummy_dir.join("none")

				dummy_dir.mkpath
				dummy_file     .touch
				dummy_directory.mkpath
				#dummy_none nothing

				entries.each do |entry|
					assert_equal entry.file?     , entry.matches?(dummy_file)
					assert_equal entry.directory?, entry.matches?(dummy_directory)
					assert_equal false           , entry.matches?(dummy_none)
				end
			end
		end #}}}



		# Installing entries: regular install {{{
		def test_install_regular
			with_test_entries do |entry|
				# Target does not exist before - must be installed, no backup
				# made
				result=entry.install!(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_exist entry.backup       # Backup was not made
			end
		end #}}}

		# Installing entries: already current {{{
		def test_install_current
			with_test_entries do |entry|
				# Install the entry
				entry.install!(false)

				# Target is already installed - no backup made
				result=entry.install!(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_exist entry.backup       # Backup was not made
			end

		end #}}}

		# Installing entries: file entry already exists (without/with overwrite) {{{
		def test_install_file_exists
			with_test_entries(:files) do |entry|
				# Create a file where we want to install the entry
				existing_contents="existing"
				entry.target.dirname.mkpath
				entry.target.write existing_contents

				# Without overwriting
				result=entry.install!(false)
				assert_equal false, result                        # Operation did not succeed
				assert_equal false, entry.installed?              # Entry is not installed
				assert_not_exist entry.backup                     # Backup was not made
				assert_equal existing_contents, entry.target.read # Target contents are not touched

				# With overwriting
				result=entry.install!(true)
				assert_equal true, result                         # Operation succeeded
				assert_equal true, entry.installed?               # Entry is not installed
				assert_exist entry.backup                         # Backup was not made
				assert_equal existing_contents, entry.backup.read # Backup contents are correct
			end
		end #}}}

		# Installing entries: directory entry already exists {{{
		def test_install_directory_exists
			with_test_entries(:directories) do |entry|
				# Create a directory where we want to install the entry
				entry.target.mkpath

				# Existing directories count as existing
				result=entry.install!(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_exist entry.backup       # Backup was not made
			end
		end #}}}

		# Installing entries: file blocked by directory {{{
		def test_install_file_blocked
			with_test_entries(:files) do |entry|
				# Create a directory where we want to install the entry
				entry.target.mkpath

				# Without overwriting
				result=entry.install!(false)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_exist entry.backup        # Backup was not made

				# With overwriting
				result=entry.install!(true)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_exist entry.backup        # Backup was not made
			end
		end #}}}

		# Installing entries: directory blocked by file {{{
		def test_install_directory_blocked
			with_test_entries(:directories) do |entry|
				# Create a file where we want to install the entry
				existing_contents="existing"
				entry.target.dirname.mkpath
				entry.target.write existing_contents

				# Without overwriting
				result=entry.install!(false)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_exist entry.backup        # Backup was not made

				# With overwriting
				result=entry.install!(true)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_exist entry.backup        # Backup was not made

				assert_equal existing_contents, entry.target.read # File is not touched
			end
		end #}}}

		# Installing entries: file was removed or replaced by the user {{{
		# Note that a directory removal/replacement cannot be detected because
		# it has no backup.
		def test_install_file_replaced
			# A file entry target (symlink) can be removed, replaced with a
			# file or replaced with a directory
			[:none, :file, :directory].each do |replace_option|
				with_test_entries(:files) do |entry|
					# Make the target already exist, so a backup will be created
					entry.target.touch!
					assert_equal false, entry.installed? # Not installed

					# Install, overwriting the target
					entry.install!(true)
					assert_equal true, entry.installed? # Installed

					# Remove or replace the target (bad user!)
					replace_with replace_option, entry.target

					# Try to install (without overwriting)
					result=entry.install!(false)
					assert_equal false, result                    # Operation did not succeed
					assert_equal false, entry.installed?          # Entry is not installed
					assert_file_type replace_option, entry.target # Target still has the correct type

					# Try to install (with overwriting)
					assert_equal false, result                    # Operation did not succeed
					assert_equal false, entry.installed?          # Entry is not installed
					assert_file_type replace_option, entry.target # Target still has the correct type
				end
			end
		end #}}}

		def test_uninstall
			# FIXME, see also table in TODO.rdoc
			# Test uninstall:
			#   * target installed, with/without backup
			#   * backup not present, target is none/file/dir (nothing done)
			#   * target was removed
			#   * target was replaced
			with_test_entries do |entry|
			end
		end

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
					dir.join(prefix, "source", ".coffle").mkpath

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

