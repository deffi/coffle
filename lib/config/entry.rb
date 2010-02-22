require 'pathname'

require 'config/filenames'

module Config
	class Entry
		include Filenames

		def initialize(base, path)
			@base=base
			@path=path
		end

		# The absolute path to the source (i. e. where the actual file is)
		def source
			@base.source.join @path
		end

		# The absolute path to the target (i. e. the config file location)
		def target
			@base.target.join unescape_path(@path)
		end

		# The absolute path to the backup file
		def backup
			@base.backup.join unescape_path(@path)
		end

		# Whether the entry represents a directory
		def directory?
			!source.symlink? && source.directory?
		end

		# The target the link should point to
		def link_target
			source.relative_path_from(target.dirname)
		end

		# Whether the target already exists (file, directory or symlink)
		def target_exist?
			target.exist? || target.symlink?
		end

		# Whether the target is a proper directory
		def target_directory?
			target.directory? && !target.symlink?
		end

		# Whether the target for the entry is a symlink to the correct location
		def target_current?
			if directory?
				# Directory entry: the target must be a directory
				target_directory?
			else
				# File entry: the target must be a symlink to the correct
				# location
				target.symlink? && target.readlink==link_target
			end
		end

		# Remove the target path (and make a backup)
		def remove!
			# Make sure the backup directory exists
			backup.dirname.mkpath

			# Move the target to the backup
			target.rename backup
		end

		# Create the target (which may not exist)
		def create!
			raise "Target exists" if target_exist?

			if directory?
				# Directory entry - create the directory
				target.mkpath
			else
				# File entry - create the symlink
				target.make_symlink link_target
			end
		end


		MDir       = "Directory "
		MCreate    = "Creating  "
		MExist     = "Exists    "
		MCurrent   = "Current   "
		MOverwrite = "Overwrite "

		def create_description
			if directory?
				"(directory)"
			else
				"-> #{link_target}"
			end
		end

		# Install the entry
		# * overwrite: If true, existing entries will be backed up and replaced.
		#   If false, existing entries will not be touched.
		def install!(overwrite)
			if target_current?
				# Nothing to do
				puts "#{MCurrent} #{target}"
			elsif target_exist?
				# Target already exists and is not current (i. e. for
				# directory entries, the target is not a directory,
				# and for file entries it is not a symlink to the
				# correct position)
				if overwrite
					puts "#{MOverwrite} #{target} #{create_description} (backup in #{backup})"
					remove!
					create!
				else
					puts "#{MExist} #{target} (not overwriting)"
				end
			else
				# Target does not exist - create it
				puts "#{MCreate} #{target} #{create_description}"
				create!
			end
		end
	end
end

