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

		def test_different_time
			with_testdir do |dir|
				file1=dir.join("file1")
				file2=dir.join("file2")

				# TODO set artificial times
				file1.touch
				wait_next_second
				file2.touch

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
				file1=dir.join("file1")
				file2=dir.join("file2")

				# TODO set artificial times
				# Note: in_same_second seems not to behave correctly when
				# called with { sleep 0.9 }
				in_same_second do |iteration|
					file1.touch
					file2.touch
				end

				assert_equal false, file2.newer?(file1)
				assert_equal false, file1.newer?(file2)

				assert_equal false, file2.older?(file1)
				assert_equal false, file1.older?(file2)

				assert_equal true, file2.current?(file1)
				assert_equal true, file1.current?(file2)
			end
		end
	end
end

