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
				file1=dir.join("file1")
				file2=dir.join("file2")
				contents="foo\nbar"

				file1.write(contents)
				file2.write(contents)
				assert_equal true, file1.file_identical?(file2)
				assert_equal true, file2.file_identical?(file1)

				file2.write(contents+" ")
				assert_equal false, file1.file_identical?(file2)
				assert_equal false, file2.file_identical?(file1)
			end

		end

		def test_absolute
			rel=Pathname.new("rel")
			assert_equal true , rel.relative?
			assert_equal false, rel.absolute?

			abs=rel.absolute
			assert_equal true , abs.absolute?
			assert_equal false, abs.relative?

			# TODO assert that they refer to the same target
		end

		def test_copy_file
			with_testdir do |dir|
				file1=dir.join("file1")
				file2=dir.join("file2")
				contents="foo\nbar"

				file1.write contents
				file1.copy_file file2

				assert_exist file2
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

				assert_not_exist file
				file.touch
				assert_exist file
				file.touch
				assert_exist file
			end
		end

		class TestEntries
			attr_accessor :file     , :file_link     , :file_link_link
			attr_accessor :directory, :directory_link, :directory_link_link
			attr_accessor :missing  , :missing_link  , :missing_link_link

			def initialize(testdir)
				# Primary
				@file      =testdir.join("file")
				@directory =testdir.join("directory")
				@missing   =testdir.join("missing")

				# Links
				@file_link      =testdir.join("file_link")
				@directory_link =testdir.join("directory_link")
				@missing_link   =testdir.join("missing_link")

				# Links to links
				@file_link_link      =testdir.join("file_link_link")
				@directory_link_link =testdir.join("directory_link_link")
				@missing_link_link   =testdir.join("missing_link_link")


				# Create
				@file     .write "moo"
				@directory.mkpath
				# @missing - nothing

				@file_link     .make_symlink("file")
				@directory_link.make_symlink("directory")
				@missing_link  .make_symlink("missing")
				
				@file_link_link     .make_symlink("file_link")
				@directory_link_link.make_symlink("directory_link")
				@missing_link_link  .make_symlink("missing_link")
			end
		end

		def test_exist
			with_testdir do |testdir|
				entries=TestEntries.new(testdir)

				# Make sure we understand exist? correctly: follows links
				assert_equal true , entries.file.exist?
				assert_equal true , entries.directory.exist?
				assert_equal false, entries.missing.exist?

				assert_equal true , entries.file_link.exist?
				assert_equal true , entries.directory_link.exist?
				assert_equal false, entries.missing_link.exist?

				assert_equal true , entries.file_link_link.exist?
				assert_equal true , entries.directory_link_link.exist?
				assert_equal false, entries.missing_link_link.exist?

				# present? acknowleges the existence of links, even if invalid
				assert_equal true , entries.file.present?
				assert_equal true , entries.directory.present?
				assert_equal false, entries.missing.present?

				assert_equal true , entries.file_link.present?
				assert_equal true , entries.directory_link.present?
				assert_equal true , entries.missing_link.present?

				assert_equal true , entries.file_link_link.present?
				assert_equal true , entries.directory_link_link.present?
				assert_equal true , entries.missing_link_link.present?

			end
		end

		def test_directory
			with_testdir do |testdir|
				entries=TestEntries.new(testdir)

				# Make sure we understand directory? correctly: follows links
				assert_equal false, entries.file.directory?
				assert_equal true , entries.directory.directory?
				assert_equal false, entries.missing.directory?

				assert_equal false, entries.file_link.directory?
				assert_equal true , entries.directory_link.directory?
				assert_equal false, entries.missing_link.directory?

				assert_equal false, entries.file_link_link.directory?
				assert_equal true , entries.directory_link_link.directory?
				assert_equal false, entries.missing_link_link.directory?

				# proper_directory? knows a symlink when it sees one
				assert_equal false, entries.file.proper_directory?
				assert_equal true , entries.directory.proper_directory?
				assert_equal false, entries.missing.proper_directory?

				assert_equal false, entries.file_link.proper_directory?
				assert_equal false, entries.directory_link.proper_directory?
				assert_equal false, entries.missing_link.proper_directory?

				assert_equal false, entries.file_link_link.proper_directory?
				assert_equal false, entries.directory_link_link.proper_directory?
				assert_equal false, entries.missing_link_link.proper_directory?

			end
		end

		def test_file
			with_testdir do |testdir|
				entries=TestEntries.new(testdir)

				# Make sure we understand file? correctly: follows links
				assert_equal true , entries.file.file?
				assert_equal false, entries.directory.file?
				assert_equal false, entries.missing.file?

				assert_equal true , entries.file_link.file?
				assert_equal false, entries.directory_link.file?
				assert_equal false, entries.missing_link.file?

				assert_equal true , entries.file_link_link.file?
				assert_equal false, entries.directory_link_link.file?
				assert_equal false, entries.missing_link_link.file?

				# proper_file? knows a symlink when it sees one
				assert_equal true , entries.file.proper_file?
				assert_equal false, entries.directory.proper_file?
				assert_equal false, entries.missing.proper_file?

				assert_equal false, entries.file_link.proper_file?
				assert_equal false, entries.directory_link.proper_file?
				assert_equal false, entries.missing_link.proper_file?

				assert_equal false, entries.file_link_link.proper_file?
				assert_equal false, entries.directory_link_link.proper_file?
				assert_equal false, entries.missing_link_link.proper_file?

			end
		end
	end
end

