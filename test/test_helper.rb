#require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/coffle'

require 'fileutils'

class Pathname
	def dump
		system "ls -laR --color=always #{self}"
	end

	def entry_type
		# Ad order: a symlink counts as !exist?, so we test for symlink before
		# exist
		if symlink?
			"symlink"
		elsif !exist?
			nil
		elsif directory?
			"directory"
		elsif file?
			"file"
		else
			"other"
		end
	end

	def tree_entries
		result=[]

		find { |path|
			result << path.relative_path_from(self)
		}

		result
	end
end

module Coffle
	module Assertions
		def assert_directory(dir, message = nil)
			dir=dir.to_s unless dir.is_a? String

			message=build_message message, '<?> is not a directory.', dir
			assert_block message do
				File.directory? dir
			end
		end

		def assert_file(file, message = nil)
			file=file.to_s unless file.is_a? String

			message=build_message message, '<?> is not a directory.', file
			assert_block message do
				File.file? file
			end
		end

		def assert_exist(path, message = nil)
			path=path.to_s unless path.is_a? String

			message=build_message message, '<?> does not exist.', path
			assert_block message do
				File.exist?(path) || File.symlink?(path)
			end
		end

		def assert_not_exist(path, message = nil)
			path=path.to_s unless path.is_a? String

			message=build_message message, '<?> exists.', path
			assert_block message do
				!(File.exist?(path) || File.symlink?(path))
			end
		end

		def assert_symlink(path, message = nil)
			path=path.to_s unless path.is_a? String

			message=build_message message, '<?> is not a symlink.', path
			assert_block message do
				File.symlink?(path)
			end
		end

		def assert_include(element, container, message = nil)
			message=build_message message, 'The container does not contain <?>.', element
			assert_block message do
				container.include? element
			end
		end

		def assert_file_equal(expected, actual, message = nil)
			assert_file expected
			assert_file actual

			message=build_message message, "File #{actual} does not match #{expected}"
			assert_block message do
				File.read(actual.to_s)==File.read(expected.to_s)
			end
		end

		def assert_tree_equal(expected, actual)
			# Iterate over existing files
			actual.find { |actual_path|
				relative_path = actual_path.relative_path_from(actual)
				expected_path = expected.join(relative_path)

				# Unexpected
				assert_block "Unexpected file #{actual_path}" do
					expected_path.exist? || expected_path.symlink?
				end

				# Wrong type
				expected_type = expected_path.entry_type
				actual_type   =   actual_path.entry_type

				assert_block "#{actual_path} is a #{actual_type}, expected a #{expected_type}" do
					actual_type == expected_type 
				end

				# Wrong symlink target
				if actual_path.symlink?
					actual_target   =   actual_path.readlink
					expected_target = expected_path.readlink

					assert_block "#{actual_path} points to #{actual_target}, expected #{expected_target}" do
						actual_target == expected_target
					end
				end
			}

			# Iterate over expected files
			expected.find { |expected_path|
				relative_path = expected_path.relative_path_from(expected)
				actual_path   = actual.join(relative_path)

				# Missing
				assert_block "Missing file #{actual_path}" do
					actual_path.exist? || expected_path.symlink?
				end
			}
		end

		def assert_file_type(file_type, target)
			case file_type
			when :none      then assert_not_exist target
			when :file      then assert_file      target
			when :directory then assert_directory target
			else raise "Unhandled file_type #{file_type.inspect}"
			end
		end
	end

	module TestHelper
		include Assertions

		Testdir="testdata/test"

		# Calls the block with a relative Pathname referring newly created,
		# empty directory and cleans up the directory afterwards.
		def with_testdir(&block)
			raise "#{Testdir} exists" if File.exist?(Testdir)

			# If this fails, don't ensure unlink it
			Dir.mkdir Testdir

			begin
				dir=Pathname.new(Testdir)
				assert dir.relative?

				yield dir
			ensure
				FileUtils.rm_r Testdir
			end
		end

		def replace_with(replace_option, target)
			target.delete

			case replace_option
			when :none      then # Nothing
			when :file      then target.touch
			when :directory then target.mkpath
			else raise "Unhandled replace_option"
			end
		end
	end
end

