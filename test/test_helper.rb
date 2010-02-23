#require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/config'

require 'fileutils'

class Pathname
	def dump
		system "ls -laR --color=always #{self}"
	end

	def touch
		open('a') {}
	end
end

module Config
	module Assertions
		def assert_directory(dir, message = nil)
			message=build_message message, '<?> is not a directory.', dir
			assert_block message do
				File.directory? dir
			end
		end

		def assert_exist(path, message = nil)
			message=build_message message, '<?> does not exist.', path
			assert_block message do
				File.exist?(path) || File.symlink?(path)
			end
		end

		def assert_not_exist(path, message = nil)
			message=build_message message, '<?> does not exist.', path
			assert_block message do
				!(File.exist?(path) || File.symlink?(path))
			end
		end

		def assert_include(element, container, message = nil)
			message=build_message message, 'The container does not contain <?>.', element
			assert_block message do
				container.include? element
			end
		end
	end

	module TestHelper
		include Assertions

		Testdir="testdata/test"

		# Calls the block with a Pathname referring newly created, empty
		# directory and cleans up the directory afterwards.
		def with_testdir(&block)
			raise "#{Testdir} exists" if File.exist?(Testdir)

			# If this fails, don't ensure unlink it
			Dir.mkdir Testdir

			begin
				yield Pathname.new(Testdir)
			ensure
				FileUtils.rm_r Testdir
			end
		end
	end
end

