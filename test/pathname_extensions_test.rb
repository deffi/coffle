#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class PathnameExtensionsTest <Test::Unit::TestCase
		include TestHelper

		def test_read
			with_testdir do |dir|
				file=dir.join("read_test")
				contents="foo\nbar"

				file.open("w") { |f| f.write contents }
				assert_equal(contents, file.read)
			end
		end

		def test_write
			with_testdir do |dir|
				file=dir.join("write_test")
				contents="foo\nbar"

				# Regular write
				file.write(contents)
				assert_equal(contents, file.read)
				file.unlink

				# Write to an existing directory
				file.mkdir
				assert_raise(RuntimeError) { file.write(contents) }
			end
		end

		def test_append
			with_testdir do |dir|
				file=dir.join("append_test")

				file.write("foo")
				file.append("bar")

				assert_equal "foobar", file.read
			end
		end

		def test_identical
			with_testdir do |dir|
				contents="foo\nbar"

				file1=dir.join("file1")
				file2=dir.join("file2")
				dir1=dir.join("dir1")
				dir2=dir.join("dir2")
				symlink1=dir.join("symlink1")
				symlink2=dir.join("symlink2")

				dir1.mkpath
				dir2.mkpath
				symlink1.make_symlink("file1")
				symlink2.make_symlink("file2")

				file1.write(contents)
				file2.write(contents)
				# File/file
				assert_equal true, file1.file_identical?(file2)
				assert_equal true, file2.file_identical?(file1)
				# File/link
				assert_equal true, file1.file_identical?(symlink1)
				assert_equal true, file1.file_identical?(symlink2)
				# Link/link
				assert_equal true, symlink1.file_identical?(symlink2)

				file2.write(contents+" ")
				# File/file
				assert_equal false, file1.file_identical?(file2)
				assert_equal false, file2.file_identical?(file1)
				# File/link
				assert_equal true, file1.file_identical?(symlink1)
				assert_equal false, file1.file_identical?(symlink2)
				# Link/link
				assert_equal false, symlink1.file_identical?(symlink2)


				# Directory comparisons, all false
				assert_equal false, dir1.file_identical?(dir2)
				assert_equal false, file1.file_identical?(dir1)
				assert_equal false, dir1.file_identical?(file1)
			end

		end

		def test_absolute
			rel=Pathname.new("rel")
			assert_equal true , rel.relative?
			assert_equal false, rel.absolute?

			abs=rel.absolute
			assert_equal true , abs.absolute?
			assert_equal false, abs.relative?
		end

		def test_copy_file
			with_testdir do |dir|
				file1=dir.join("file1")
				file2=dir.join("file2")
				contents="foo\nbar"

				file1.write contents
				file1.copy_file file2

				assert_present file2
				assert_file_equal file1, file2 
			end
		end

		def test_set_time
			with_testdir do |dir|
				file1=dir.join("file1"); file1.touch
				file2=dir.join("file2"); file2.touch

				file2.set_older(file1)
				assert_equal true, (file2.mtime<file1.mtime)
				assert_equal true, (file2.atime<file1.atime)

				file2.set_newer(file1)
				assert_equal true, (file2.mtime>file1.mtime)
				assert_equal true, (file2.atime>file1.atime)

				file2.set_same_time(file1)
				assert_equal true, (file2.mtime==file1.mtime)
				assert_equal true, (file2.atime==file1.atime)

				t=Time.now
				file1.set_time t+1
				file2.set_time t+2
				assert_equal true, (file2.mtime>file1.mtime)
				assert_equal true, (file2.atime>file1.atime)
			end
		end

		def test_different_time
			with_testdir do |dir|
				file1=dir.join("file1"); file1.touch
				file2=dir.join("file2"); file2.touch

				file2.set_newer(file1)

				assert_equal true , file2.newer?(file1)
				assert_equal false, file1.newer?(file2)

				assert_equal false, file2.older?(file1)
				assert_equal true , file1.older?(file2)

				assert_equal true , file2.current?(file1)
				assert_equal false, file1.current?(file2)
			end
		end

		def test_same_time
			with_testdir do |dir|
				file1=dir.join("file1"); file1.touch
				file2=dir.join("file2"); file2.touch

				file2.set_same_time(file1)

				assert_equal false, file2.newer?(file1)
				assert_equal false, file1.newer?(file2)

				assert_equal false, file2.older?(file1)
				assert_equal false, file1.older?(file2)

				assert_equal true, file2.current?(file1)
				assert_equal true, file1.current?(file2)
			end
		end

		def test_touch
			with_testdir do |dir|
				file=dir.join("file")

				assert_not_present file
				file.touch
				assert_present file
				file.touch
				assert_present file
			end
		end

		def test_exist
			with_testdir do |testdir|
				dir_entries=DirectoryEntries.new(testdir)

				# Make sure we understand exist? correctly: follows links
				assert_equal true , dir_entries.file     .exist?
				assert_equal true , dir_entries.directory.exist?
				assert_equal false, dir_entries.missing  .exist?

				assert_equal true , dir_entries.file_link     .exist?
				assert_equal true , dir_entries.directory_link.exist?
				assert_equal false, dir_entries.missing_link  .exist?

				assert_equal true , dir_entries.file_link_link     .exist?
				assert_equal true , dir_entries.directory_link_link.exist?
				assert_equal false, dir_entries.missing_link_link  .exist?

				# present? acknowleges the existence of links, even if invalid
				assert_equal true , dir_entries.file     .present?
				assert_equal true , dir_entries.directory.present?
				assert_equal false, dir_entries.missing  .present?

				assert_equal true , dir_entries.file_link     .present?
				assert_equal true , dir_entries.directory_link.present?
				assert_equal true , dir_entries.missing_link  .present?

				assert_equal true , dir_entries.file_link_link     .present?
				assert_equal true , dir_entries.directory_link_link.present?
				assert_equal true , dir_entries.missing_link_link  .present?
			end
		end

		def test_directory
			with_testdir do |testdir|
				dir_entries=DirectoryEntries.new(testdir)

				# Make sure we understand directory? correctly: follows links
				assert_equal false, dir_entries.file     .directory?
				assert_equal true , dir_entries.directory.directory?
				assert_equal false, dir_entries.missing  .directory?

				assert_equal false, dir_entries.file_link     .directory?
				assert_equal true , dir_entries.directory_link.directory?
				assert_equal false, dir_entries.missing_link  .directory?

				assert_equal false, dir_entries.file_link_link     .directory?
				assert_equal true , dir_entries.directory_link_link.directory?
				assert_equal false, dir_entries.missing_link_link  .directory?

				# proper_directory? knows a symlink when it sees one
				assert_equal false, dir_entries.file     .proper_directory?
				assert_equal true , dir_entries.directory.proper_directory?
				assert_equal false, dir_entries.missing  .proper_directory?

				assert_equal false, dir_entries.file_link     .proper_directory?
				assert_equal false, dir_entries.directory_link.proper_directory?
				assert_equal false, dir_entries.missing_link  .proper_directory?

				assert_equal false, dir_entries.file_link_link     .proper_directory?
				assert_equal false, dir_entries.directory_link_link.proper_directory?
				assert_equal false, dir_entries.missing_link_link  .proper_directory?
			end
		end

		def test_file
			with_testdir do |testdir|
				dir_entries=DirectoryEntries.new(testdir)

				# Make sure we understand file? correctly: follows links
				assert_equal true , dir_entries.file     .file?
				assert_equal false, dir_entries.directory.file?
				assert_equal false, dir_entries.missing  .file?

				assert_equal true , dir_entries.file_link     .file?
				assert_equal false, dir_entries.directory_link.file?
				assert_equal false, dir_entries.missing_link  .file?

				assert_equal true , dir_entries.file_link_link     .file?
				assert_equal false, dir_entries.directory_link_link.file?
				assert_equal false, dir_entries.missing_link_link  .file?

				# proper_file? knows a symlink when it sees one
				assert_equal true , dir_entries.file     .proper_file?
				assert_equal false, dir_entries.directory.proper_file?
				assert_equal false, dir_entries.missing  .proper_file?

				assert_equal false, dir_entries.file_link     .proper_file?
				assert_equal false, dir_entries.directory_link.proper_file?
				assert_equal false, dir_entries.missing_link  .proper_file?

				assert_equal false, dir_entries.file_link_link     .proper_file?
				assert_equal false, dir_entries.directory_link_link.proper_file?
				assert_equal false, dir_entries.missing_link_link  .proper_file?
			end
		end

		def test_empty
			with_testdir do |testdir|
				# Directories with certain contents
				empty_directory     =testdir.join("empty_dir")
				file_directory      =testdir.join("file_dir")
				directory_directory =testdir.join("directory_dir")
				symlink_directory   =testdir.join("symlink_dir")

				# Links to above directories
				empty_directory_link     =testdir.join("empty_link")
				file_directory_link      =testdir.join("file_link")
				directory_directory_link =testdir.join("directory_link")
				symlink_directory_link   =testdir.join("symlink_link")

				# Contents
				empty     =empty_directory    .join("foo")
				file      =file_directory     .join("bar")
				directory =directory_directory.join("baz")
				symlink   =symlink_directory  .join("qux")


				# Create the directories
				empty_directory     .mkpath
				file_directory      .mkpath
				directory_directory .mkpath
				symlink_directory   .mkpath

				# Create the contents
				# empty.nothing
				file     .touch
				directory.mkdir
				symlink  .make_symlink(".")

				# Create the links
				empty_directory_link    .make_symlink("empty_dir")
				file_directory_link     .make_symlink("file_dir")
				directory_directory_link.make_symlink("directory_dir")
				symlink_directory_link  .make_symlink("symlink_dir")


				# Emptyness of the testdir
				assert_equal false, testdir.empty?

				# Emptiness of the directories
				assert_equal true , empty_directory    .empty?
				assert_equal false, file_directory     .empty?
				assert_equal false, directory_directory.empty?
				assert_equal false, symlink_directory  .empty?

				# Links treated like files
				assert_equal true , empty_directory_link    .empty?
				assert_equal false, file_directory_link     .empty?
				assert_equal false, directory_directory_link.empty?
				assert_equal false, symlink_directory_link  .empty?

				# Emptiness of the contents
				assert_raise(Errno::ENOTDIR) { empty    .empty? } # can't call empty? for non-directory
				assert_raise(Errno::ENOTDIR) { file     .empty? } # can't call empty? for non-directory
				assert_nothing_raised        { directory.empty? } # this one is fine, it's a directory
				assert_nothing_raised        { symlink  .empty? } # this one too, it's a symlink to a directory
			end
		end
	end
end

