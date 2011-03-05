require 'coffle/entry'

module Coffle
	# An entry representing a proper file (no symlinks, no specials)
	class FileEntry <Entry
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
			"File"
		end

		def create_description
			"-> #{link_target}"
		end


		############
		## Status ##
		############

		def built?
			output.proper_file? and org.proper_file?
		end

		def blocked_by?(pathname)
			# File entries are only blocked by proper directories (everything
			# else can be backuped and removed)
			pathname.proper_directory?
		end

		def installed?
			# File entry: the target must be a symlink to the correct location
			# Regardless of whether that location exists
			target.symlink? && target.readlink==link_target
		end

		# The source has to be rebuilt (because it has been modified after it
		# was last built, or it doesn't exist)
		def outdated?
			built=built?
			skipped=skipped?

			if built and not skipped
				# Is not current
				!org.current?(source)
			elsif skipped and not built
				source.mtime>@timestamp
			else
				# Neither built nor skipped (not built), or both built and
				# skipped (inconsistent) - always outdated
				true
			end
		end

		# The built file has been modified, i. e. we cannot rebuild it without
		# overwriting the changes
		# Only meaningful if current.
		def modified?
			if !output.present?
				false
			elsif !org.present?
				false
			else
				!output.file_identical?(org)
			end
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
			# Create the directory if it does not exist
			output.dirname.mkpath
			org   .dirname.mkpath

			builder=Builder.new(self)
			result=builder.process(source.read)

			if builder.skipped?
				output.delete if output.present?
				org   .delete if org   .present?
			else
				output.write result
				org   .write result
			end

			@skipped  =builder.skipped?
			@timestamp=(Time.now if skipped?)
		end
		
		# Create the target (which must not exist)
		def install!
			raise "Target exists" if target.present?

			# File entry - create the containing directory and the symlink
			target.dirname.mkpath
			target.make_symlink link_target
		end

		# Preconditions: target exists, does not block, backup does not exist
		def install_overwrite!
			# Make sure the backup directory exists
			backup.dirname.mkpath

			# Move the file to the backup
			target.rename backup

			# Now we can regularly install the file
			install!
		end

		# Preconditions: target installed
		def uninstall!
			raise "Target is not installed" if !installed?

			target.delete

			# We must remove the backup, or the entry will count as removed
			backup.rename target if backup.present?
		end
	end
end

