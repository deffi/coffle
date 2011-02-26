require 'coffle/entry'

module Coffle
	# An entry representing a proper directory (no symlinks)
	class DirectoryEntry <Entry
		def type; "Dir"; end
		def create_description; "(directory)"; end

		def initialize(*args); super(*args); end

		def built?
			build.proper_directory?
		end

		def blocked_by?(pathname)
			# Directory entries are blocked by anything except directories
			# (proper directories or symlinks to directories)
			pathname.present? and not pathname.directory?
		end

		# Whether the target for the entry is a symlink to the correct location
		def installed?
			# Directory entry: the target must be a directory (proper directory
			# or symlink to directory)
			target.directory?
		end

		# Create the target (which must not exist)
		def create!
			raise "Target exists" if target.present?

			# Directory entry - create the directory
			target.mkpath
		end

		# The source has to be rebuilt (because it has been modified after it
		# was last built, or it doesn't exist)
		def outdated?
			# TODO skipped
			# Existing directories are never outdated
			!built?
		end

		# The built file has been modified, i. e. we cannot rebuild it without
		# overwriting the changes
		def modified?
			# TODO skipped
			# Directories are never modified
			false
		end

		# Unconditionally build it
		def do_build!
			puts "#{MBuild} #{build}" if @verbose

			build.mkpath
			org  .mkpath
		end
	end
end

