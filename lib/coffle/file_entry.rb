require 'coffle/entry'

module Coffle
	# An entry representing a proper file (no symlinks, no specials)
	class FileEntry <Entry
		def type; "File"; end
		def create_description; "-> #{link_target}"; end

		def initialize(*args); super(*args); end

		def built?
			build.proper_file?
		end

		def blocked_by?(pathname)
			# File entries are only blocked by proper directories (everything
			# else can be backuped and removed)
			pathname.proper_directory?
		end

		def installed?
			# File entry: the target must be a symlink to the correct location
			target.symlink? && target.readlink==link_target
		end

		# Create the target (which must not exist)
		def create!
			raise "Target exists" if target.present?

			# File entry - create the containing directory and the symlink
			target.dirname.mkpath
			target.make_symlink link_target
		end

		# The source has to be rebuilt (because it has been modified after it
		# was last built, or it doesn't exist)
		def outdated?
			if !built?
				# Does not exist
				true
			else
				# Is not current
				!@build.current?(@source)
			end
		end

		# The built file has been modified, i. e. we cannot rebuild it without
		# overwriting the changes
		def modified?
			# TODO skipped
			if  !built?
				# What has not been built cannot be modified
				false
			else
				!@build.file_identical?(@org)
			end
		end

		# Unconditionally build it
		def do_build!
			puts "#{MBuild} #{build}" if @verbose

			# Create the directory if it does not exist
			build.dirname.mkpath
			org.dirname.mkpath

			# TODO test dereferencing
			Builder.build source, build
			build.copy_file org
		end

	end
end

