require 'pathname'

require 'coffle/filenames'

module Coffle
	class Entry
		include Filenames

		# The relative path
		attr_reader :path

		# Absolute paths to entries
		attr_reader :source, :build, :target, :backup

		# Relative link target
		attr_reader :link_target

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize(coffle, path, options={})
			@coffle=coffle
			@path=path

			@verbose = options.fetch :verbose, false

			# The absolute path to the source (i. e. the template)
			@source=@coffle.source.join @path
			# The absolute path to the built file
			@build=@coffle.build.join @path
			# The absolute path to the target (i. e. the config file location)
			@target=@coffle.target.join unescape_path(@path)
			# The absolute path to the backup file
			@backup=@coffle.backup.join unescape_path(@path)

			# The target the link should point to
			@link_target=build.relative_path_from(target.dirname)
		end

		# Whether the entry represents a directory
		def directory?
			!source.symlink? && source.directory?
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

		def built?
			build.exist?
		end

		def build_current?
			if directory?
				built?
			else
				built? and build.mtime >= source.mtime
			end
		end

		# Remove the target path (and make a backup)
		def remove!
			# Make sure the backup directory exists
			backup.dirname.mkpath

			if target.directory? && backup.directory?
				# The target is a directory and the backup already exists.
				# This can happen if a file inside the directory was backed up
				# before the directory itself.

				# Move all the files inside the directory to the backup
				target.entries.reject { |entry|
					# Exclude . and ..
					['.', '..'].include? entry.to_s
				}.each { |entry|
					target.join(entry).rename backup.join(entry)
				}

				target.rmdir
			else
				# Move the target to the backup
				target.rename backup
			end
		end


		# Create the target (which may not exist)
		def create!
			raise "Target exists" if target_exist?

			if directory?
				# Directory entry - create the directory
				target.mkpath
			else
				# File entry - create the containing directory and the symlink
				target.dirname.mkpath
				target.make_symlink link_target
			end
		end

		MDir       = "Directory "
		MCreate    = "Creating  "
		MExist     = "Exists    "
		MCurrent   = "Current   "
		MOverwrite = "Overwrite "
		MBuild     = "Building  "

		def build!(rebuild=false)
			if build_current? && !rebuild
				puts "#{MCurrent} #{build}" if @verbose
			else
				puts "#{MBuild} #{build}" if @verbose
				# The build file can be overwritten
				if directory?
					build.mkpath
				else
					# Create the directory if it does not exist
					build.dirname.mkpath

					# TODO test dereferencing
					Builder.build source.to_s, build.to_s
				end
			end
		end


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
			build! if (!built? || !build_current?)

			if target_current?
				# Nothing to do
				puts "#{MCurrent} #{target}" if @verbose
			elsif target_exist?
				# Target already exists and is not current (i. e. for
				# directory entries, the target is not a directory,
				# and for file entries it is not a symlink to the
				# correct position)
				if overwrite
					puts "#{MOverwrite} #{target} #{create_description} (backup in #{backup})" if @verbose
					remove!
					create!
				else
					puts "#{MExist} #{target} (not overwriting)" if @verbose
				end
			else
				# Target does not exist - create it
				puts "#{MCreate} #{target} #{create_description}" if @verbose
				create!
			end
		end

	end
end

