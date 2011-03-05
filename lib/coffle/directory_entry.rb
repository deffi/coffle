require 'coffle/entry'

module Coffle
	# An entry representing a proper directory (no symlinks)
	class DirectoryEntry <Entry
		##################
		## Construction ##
		##################

		def initialize(*args)
			super(*args)
		end


		################
		## Properties ##
		################

		def type
			"Dir"
		end

		def create_description
			"(directory)"
		end


		############
		## Status ##
		############

		def built?
			output.proper_directory?
		end

		def blocked_by?(pathname)
			# Directory entries are blocked by anything except directories
			# (proper directories or symlinks to directories)
			pathname.present? and not pathname.directory?
		end

		def installed?
			# Directory entry: the target must be a directory (proper directory
			# or symlink to directory)
			target.directory?
		end

		# The source has to be rebuilt (because it has been modified after it
		# was last built, or it doesn't exist)
		def outdated?
			# Existing directories are never outdated
			!built?
		end

		# The built file has been modified, i. e. we cannot rebuild it without
		# overwriting the changes
		def modified?
			# Directories are never modified
			false
		end


		#############
		## Actions ##
		#############

		# These methods perform their respective operation unconditionally,
		# without checking for errors. It is the caller's responsibility to
		# performe any necessary checks.

		private

		# Unconditionally build it
		def build!
			output.mkpath
			org   .mkpath

			# Directories are never skipped
			@skipped  =false
			@timestamp=nil
		end

		# Create the target (which must not exist)
		def install!
			raise "Target exists" if target.present?

			# Directory entry - create the directory
			target.mkpath
		end

		# Preconditions: target exists, does not block, backup does not exist
		def install_overwrite!
			# This may not happen because for a directory entry, an existing
			# target is either current (if it's a directory or a symlink to a
			# directory) or blocking (it it's anything else), and both must
			# be checked before calling this method.
			raise "Trying to overwrite a directory"
		end

		# Preconditions: target installed
		def uninstall!
			raise "Target is not installed" if !installed?

			# Only uninstall if the target is a proper directory
			if target.proper_directory?
				# Delete the directory if it is empty
				if target.empty?
					target.rmdir
				end
			end
		end
	end
end

