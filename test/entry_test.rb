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
		# * output: .output/
		# * org:    .output/.org
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
					when :files       then entries.select { |e| e.is_a? FileEntry }
					when :directories then entries.select { |e| e.is_a? DirectoryEntry }
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
					assert entry.output.absolute?
					assert entry.target.absolute?
					assert entry.backup.absolute?
				end

				# The path names must have the correct values
				assert_equal dir.join("source"                    , "_foo").absolute, @foo.source
				assert_equal dir.join("source", ".output"         , "_foo").absolute, @foo.output
				assert_equal dir.join("source", ".output", ".org" , "_foo").absolute, @foo.org
				assert_equal dir.join("source", ".backup"         , ".foo").absolute, @foo.backup
				assert_equal dir.join("target"                    , ".foo").absolute, @foo.target
				#assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.foo$/,
				#	                                                                  @foo.backup.to_s

				assert_equal dir.join("source"                    , "_bar").absolute, @bar.source
				assert_equal dir.join("source", ".output"         , "_bar").absolute, @bar.output
				assert_equal dir.join("source", ".output", ".org" , "_bar").absolute, @bar.org
				assert_equal dir.join("source", ".backup"         , ".bar").absolute, @bar.backup
				assert_equal dir.join("target"                    , ".bar").absolute, @bar.target
				#assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.bar$/,
				#	                                                                  @bar.backup.to_s

				assert_equal dir.join("source"                    , "_bar", "baz").absolute, @baz.source
				assert_equal dir.join("source", ".output"         , "_bar", "baz").absolute, @baz.output
				assert_equal dir.join("source", ".output", ".org" , "_bar", "baz").absolute, @baz.org
				assert_equal dir.join("source", ".backup"         , ".bar", "baz").absolute, @baz.backup
				assert_equal dir.join("target"                    , ".bar", "baz").absolute, @baz.target
				#assert_match /^#{dir.join("source", ".backups").absolute}\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d\/.bar\/baz$/,
				#	                                                                         @baz.backup.to_s
			end
		end #}}}

		def test_with_test_entries #{{{
			# Make sure the with_test_entries selection works properly

			with_test_entries(:directories) do |entry|
				assert_equal true , entry.is_a?(DirectoryEntry)
				assert_equal false, entry.is_a?(FileEntry)
			end

			with_test_entries(:files) do |entry|
				assert_equal true , entry.is_a?(FileEntry)
				assert_equal false, entry.is_a?(DirectoryEntry)
			end
		end #}}}

		def test_entry_class #{{{
			with_test_data do |dir, entries|
				assert_equal FileEntry     , @foo.class
				assert_equal DirectoryEntry, @bar.class
				assert_equal FileEntry     , @baz.class
			end
		end #}}}

		def test_link_target #{{{
			with_test_data do |dir, entries|
				# link_target must return a relative link to the output path
				assert_equal    "../source/.output/_foo"    , @foo.link_target.to_s
				assert_equal    "../source/.output/_bar"    , @bar.link_target.to_s
				assert_equal "../../source/.output/_bar/baz", @baz.link_target.to_s
			end
		end #}}}

		def test_installed #{{{
			with_test_entries do |entry|
				# Make sure that the target does not exist (not created yet)
				assert_not_present entry.target

				# If the target does not exist, installed must return false
				assert_equal false, entry.installed?

				# If the target is a file, installed? must return false
				entry.target.touch!
				assert_equal false, entry.installed?
				entry.target.delete

				# If the target is a directory installed? must return true
				# exactly for directory entries
				entry.target.mkdir
				assert_equal entry.is_a?(DirectoryEntry), entry.installed?
				entry.target.delete

				# If the target is a symlink to a non-existing file,
				# installed? must return false
				entry.target.make_symlink "missing"
				assert_equal false, entry.installed?
				entry.target.delete

				# If the target is a symlink to a file (other than the
				# correct link target), installed? must return false
				entry.target.dirname.join("dummy").touch!
				entry.target.make_symlink "dummy"
				assert_equal false, entry.installed?
				entry.target.delete
				entry.target.dirname.join("dummy").delete

				# If the target is a symlink to a directory, installed? must
				# return true exactly for directories.
				entry.target.make_symlink "."
				assert_equal entry.is_a?(DirectoryEntry), entry.installed?
				entry.target.delete
			end
		end #}}}

		def test_create #{{{
			with_test_entries do |entry|
				# If the target already exists and is a directory, install! must
				# raise an exception
				entry.target.mkpath
				assert_raise(RuntimeError) { entry.install! }
				entry.target.rmdir

				# If the target already exists and is a file, install! must
				# raise an exception
				entry.target.dirname.mkpath
				entry.target.touch
				assert_raise(RuntimeError) { entry.install! }
				entry.target.delete

				# If the target does not exist, install! must succeed, the
				# target must exist and be current, and be a directory exactly
				# for directory entries
				assert_nothing_raised { entry.install! }
				assert_present entry.target
				assert         entry.target.present?
				assert         entry.installed?
				assert_equal   entry.is_a?(DirectoryEntry), entry.target.proper_directory?
			end
		end #}}}

		def test_build #{{{
			with_test_entries do |entry|
				# Before building, the output and org items may not exist
				assert_not_present entry.output
				assert_not_present entry.org
				assert !entry.built?

				# After building, the output and org items must exist and be identical
				entry.build
				assert_present entry.output
				assert_present entry.org
				assert entry.built?

				if entry.is_a?(DirectoryEntry)
					assert_tree_equal(entry.output, entry.org)
				else
					assert_file_equal(entry.output, entry.org)
				end

				# For directory entries, the built file must be a directory
				if entry.is_a?(DirectoryEntry)
					assert_proper_directory entry.output
					assert_proper_directory entry.org
				else
					assert_proper_file entry.output
					assert_proper_file entry.org
				end
			end
		end #}}}

		def test_build_outdated #{{{
			# Test rebuilding of outdated entries, this only applies to
			# file entries
			with_test_entries(:files) do |entry|
				# Build - must be current
				entry.build
				assert !entry.outdated?

				# Outdate - must be outdated
				entry.output.set_older(entry.source)
				assert entry.outdated?

				# Rebuild - must be current
				entry.build
				assert !entry.outdated?
			end
		end #}}}

		def test_build_modified #{{{
			# Test rebuilding of modified entries, this only applies to
			# file entries
			with_test_entries(:files) do |entry|
				# Build - must be current
				entry.build
				assert !entry.outdated?

				# Outdate and modify - must be outdated
				entry.output.append "x"
				entry.output.set_older(entry.source)
				assert entry.outdated?
				assert entry.modified?

				# Rebuild - must still be outdated because modified
				# entries are not overwritten
				entry.build
				assert entry.outdated?

				# Rebuild with overwrite - must be current
				entry.build(false, true)
				assert !entry.outdated?

				# Modify only
				entry.output.append "x"
				assert !entry.outdated?
				assert entry.modified?

				# Rebuild with overwrite - must no longer be modified,
				# even though it was current before
				assert !entry.outdated?
				entry.build(false, true)
				assert !entry.outdated?
				assert !entry.modified?
			end
		end #}}}

		def test_outdated #{{{
			with_test_entries do |entry|
				# Before building, the output must be outdated (it does
				# not exist)
				assert entry.outdated?

				# After building, the output must not be outdated
				entry.build
				assert !entry.outdated?

				# If the output file is older than the source file,
				# outdated? must return true, except for directores,
				# which are never outdated
				entry.output.set_older(entry.source)
				assert  entry.outdated?                                     if !entry.is_a?(DirectoryEntry)
				assert !entry.outdated?, "A directory must not be outdated" if  entry.is_a?(DirectoryEntry)

				# After building, outdated? must return false again
				entry.build
				assert !entry.outdated?
			end
		end #}}}

		def test_modified #{{{
			with_test_entries do |entry|
				entry.build

				if entry.is_a?(DirectoryEntry)
					assert_equal false, entry.modified?
				else
					assert_equal false, entry.modified?

					entry.output.append "x"
					assert_equal true, entry.modified?
				end
			end
		end #}}}

		def test_build_file_in_nonexistent_directory #{{{
			with_test_data do |dir, entries|
				# Building a file (@baz) in a non-existing directory (@bar)
				assert_not_present @bar.output
				assert_not_present @bar.org
				@baz.build
				assert_proper_directory @bar.output
				assert_proper_directory @bar.org
			end
		end #}}}

		def test_blocked_by? #{{{
			# TODO add selection by type to with_test_data, or Enumerable.select_by_class
			with_test_data do |testdir, entries|
				dir_entries=DirectoryEntries.new(testdir)

				entries.select { |e| e.is_a? FileEntry }.each do |entry|
					assert_equal false, entry.blocked_by?(dir_entries.missing  )
					assert_equal false, entry.blocked_by?(dir_entries.file     )
					assert_equal true , entry.blocked_by?(dir_entries.directory)

					assert_equal false, entry.blocked_by?(dir_entries.missing_link  )
					assert_equal false, entry.blocked_by?(dir_entries.file_link     )
					assert_equal false, entry.blocked_by?(dir_entries.directory_link)

					assert_equal false, entry.blocked_by?(dir_entries.missing_link_link  )
					assert_equal false, entry.blocked_by?(dir_entries.file_link_link     )
					assert_equal false, entry.blocked_by?(dir_entries.directory_link_link)
				end

				entries.select { |e| e.is_a? DirectoryEntry }.each do |entry|
					assert_equal false , entry.blocked_by?(dir_entries.missing  )
					assert_equal true  , entry.blocked_by?(dir_entries.file     )
					assert_equal false , entry.blocked_by?(dir_entries.directory)

					assert_equal true , entry.blocked_by?(dir_entries.missing_link  )
					assert_equal true , entry.blocked_by?(dir_entries.file_link     )
					assert_equal false, entry.blocked_by?(dir_entries.directory_link)

					assert_equal true , entry.blocked_by?(dir_entries.missing_link_link  )
					assert_equal true , entry.blocked_by?(dir_entries.file_link_link     )
					assert_equal false, entry.blocked_by?(dir_entries.directory_link_link)
				end
			end
		end #}}}



		# Installing entries: regular install {{{
		def test_install_regular
			with_test_entries do |entry|
				# Target does not exist before - must be installed, no backup
				# made
				result=entry.install(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_present entry.backup     # Backup was not made
			end
		end #}}}

		# Installing entries: already current {{{
		def test_install_current
			with_test_entries do |entry|
				# Install the entry
				entry.install(false)

				# Target is already installed - no backup made
				result=entry.install(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_present entry.backup     # Backup was not made
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
				result=entry.install(false)
				assert_equal false, result                        # Operation did not succeed
				assert_equal false, entry.installed?              # Entry is not installed
				assert_not_present entry.backup                   # Backup was not made
				assert_equal existing_contents, entry.target.read # Target contents are not touched

				# With overwriting
				result=entry.install(true)
				assert_equal true, result                         # Operation succeeded
				assert_equal true, entry.installed?               # Entry is not installed
				assert_present entry.backup                       # Backup was not made
				assert_equal existing_contents, entry.backup.read # Backup contents are correct
			end
		end #}}}

		# Installing entries: directory entry already exists {{{
		def test_install_directory_exists
			with_test_entries(:directories) do |entry|
				# Create a directory where we want to install the entry
				entry.target.mkpath

				# Existing directories count as existing
				assert_equal true, entry.installed? # Entry is installed
				result=entry.install(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_present entry.backup     # Backup was not made
			end

			with_test_entries(:directories) do |entry|
				# Create a directory where we want to install the entry
				entry.target.dirname.join("__test").mkpath
				entry.target.make_symlink("__test")

				# Existing directories count as existing
				assert_equal true, entry.installed? # Entry is installed
				result=entry.install(false)
				assert_equal true, result           # Operation succeeded
				assert_equal true, entry.installed? # Entry is installed
				assert_not_present entry.backup     # Backup was not made
			end
		end #}}}

		# Installing entries: file blocked by directory {{{
		def test_install_file_blocked
			with_test_entries(:files) do |entry|
				# Create a directory where we want to install the entry
				entry.target.mkpath

				# Without overwriting
				result=entry.install(false)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_present entry.backup      # Backup was not made

				# With overwriting
				result=entry.install(true)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_present entry.backup      # Backup was not made
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
				result=entry.install(false)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_present entry.backup      # Backup was not made

				# With overwriting
				result=entry.install(true)
				assert_equal false, result           # Operation did not succeed
				assert_equal false, entry.installed? # Entry is not installed
				assert_not_present entry.backup      # Backup was not made

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
					# Use a symlink because they might not be recognized as
					# existing if they are invalid in the backup.
					entry.target.dirname.mkpath
					entry.target.make_symlink("invalid")
					assert_equal false, entry.installed? # Not installed

					# Install, overwriting the target
					result=entry.install(true)
					assert_equal true, result
					assert_equal true, entry.installed? # Installed

					# Remove or replace the target (bad user!)
					replace_with replace_option, entry.target

					# Try to install (without overwriting)
					result=entry.install(false)
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


		# Uninstalling entries: individual regular uninstall {{{
		def test_uninstall
			# Each entry individually
			with_test_entries do |entry|
				assert_equal false, entry.installed?

				entry.install(false)
				assert_equal true, entry.installed?

				entry.uninstall
				assert_equal false, entry.installed?
			end
		end
		#}}}

		# Uninstalling entries: collective regular uninstall {{{
		def test_uninstall_collective
			with_test_data do |dir, entries|
				entries        .each do |entry|; assert_equal false, entry.installed?; end
				entries        .each do |entry|; entry.install(false)                ; end
				entries        .each do |entry|; assert_equal true , entry.installed?; end
				entries.reverse.each do |entry|; entry.uninstall                     ; end
				entries        .each do |entry|; assert_equal false, entry.installed?; end
			end
		end
		#}}}
		
		# Uninstalling entries: file entry regular uninstall with restore {{{
		def test_uninstall_with_restore
			with_test_entries(:files) do |entry|
				original_contents="original_contents"

				# State before
				assert_equal false, entry.installed?
				assert_equal false, entry.target.present?
				assert_equal false, entry.backup.present?

				# Write a previously existing file
				entry.target.dirname.mkpath
				entry.target.write original_contents
				assert_equal false, entry.installed?
				assert_equal true , entry.target.present?
				assert_equal false, entry.backup.present?

				# Install the entry (overwriting)
				result=entry.install(true)
				assert_equal true, result
				assert_equal true, entry.installed?
				assert_equal true, entry.target.present?
				assert_equal true, entry.backup.present?
				assert_equal original_contents, entry.backup.read

				# Uninstall the entry
				result=entry.uninstall
				assert_equal true , result
				assert_equal false, entry.installed?
				assert_equal true , entry.target.present?
				assert_equal false, entry.backup.present?
				assert_equal original_contents, entry.target.read
			end
		end
		#}}}

		# Uninstalling entries: not installed {{{
		def test_uninstall_not_installed
			with_test_entries do |entry|
				# Uninstall the entry
				result=entry.uninstall
				assert_equal true , result
				assert_equal false, entry.installed?
				assert_equal false, entry.target.present?
				assert_equal false, entry.backup.present?
			end
		end
		#}}}

		# Uninstalling entries: not installed, something else there {{{
		def test_uninstall_not_installed_present
			with_test_entries do |entry|
				original_contents="original_contents"

				# Write a previously existing file
				entry.target.dirname.mkpath
				entry.target.write original_contents

				# Uninstall the entry
				result=entry.uninstall
				assert_equal true , result
				assert_equal false, entry.installed?
				assert_equal true , entry.target.present?
				assert_equal false, entry.backup.present?
				assert_equal original_contents, entry.target.read

				# Delete the file so it doesn't block a directory
				entry.target.delete
			end
		end
		#}}}

		# Uninstalling entries: file entry target removed or replaced {{{
		def test_uninstall_replaced
			# A file entry target (symlink) can be removed, replaced with a
			# file or replaced with a directory
			[:none, :file, :directory].each do |replace_option|
				with_test_entries(:files) do |entry|
					original_contents="original_contents"

					# Make the target already exist
					entry.target.dirname.mkpath
					entry.target.write original_contents
					assert_equal false, entry.installed? # Not installed

					# Install, overwriting the target
					result=entry.install(true)
					assert_equal true, entry.installed?
					assert_equal true, entry.backup.present?

					# Remove or replace the target (bad user!)
					replace_with replace_option, entry.target
					assert_equal false, entry.installed?

					# Try to uninstall
					result=entry.uninstall
					assert_equal false, result
					assert_equal false, entry.installed?
					assert_equal true, entry.backup.present?
					assert_file_type replace_option, entry.target # Target still has the correct type
				end
			end
		end
		#}}}


		# TODO also compare file contents
		# TODO also test uninstall
		# TODO also test backup dir
		# TODO include installation into existing symlink directory
		def test_full
			with_testdir do |dir|
				# source          in actual/source
				# target          in actual/target
				# expected source in expected/source (containing .output)
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
				expected.join("target", ".foo").make_symlink("../source/.output/_foo")
				expected.join("target", ".bar").mkdir
				expected.join("target", ".bar", "baz").make_symlink("../../source/.output/_bar/baz")

				# Create the expected output data
				expected.join("source", ".output").mkpath
				expected.join("source", ".output", "_foo").touch
				expected.join("source", ".output", "_bar").mkdir
				expected.join("source", ".output", "_bar", "baz").touch

				# Create the expected org data
				expected.join("source", ".output", ".org").mkpath
				expected.join("source", ".output", ".org", "_foo").touch
				expected.join("source", ".output", ".org", "_bar").mkdir
				expected.join("source", ".output", ".org", "_bar", "baz").touch

				# Create the coffle (also creates the output and target directories)
				coffle=Coffle.new("#{dir}/actual/source", "#{dir}/actual/target")

				coffle.entries.each do |entry|
					entry.build
					entry.install(false)
				end

				assert_tree_equal(expected, actual)
				#p expected.tree_entries
			end
		end
	end
end

