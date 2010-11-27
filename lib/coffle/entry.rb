require 'pathname'

require 'coffle/filenames'

module Coffle
	class Entry
		include Filenames

		################
		## Attributes ##
		################

		# The relative path
		attr_reader :path

		# Absolute paths to entries
		attr_reader :source, :build, :org, :target, :backup

		# Relative link target from target to build
		attr_reader :link_target


		##################
		## Construction ##
		##################

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize(coffle, path, options={})
			@coffle=coffle
			@path=path

			@verbose = options.fetch :verbose, false

			@source=@coffle.source.join @path # The absolute path to the source (i. e. the template)
			@build =@coffle.build .join @path # The absolute path to the built file
			@org   =@coffle.org   .join @path # The absolute path to the original of the built file
			@target=@coffle.target.join unescape_path(@path) # The absolute path to the target (i. e. the config file location)
			@backup=@coffle.backup.join unescape_path(@path) # The absolute path to the backup file

			# The target the link should point to
			@link_target=build.relative_path_from(target.dirname)
		end


		################
		## Properties ##
		################

		# Whether the entry represents a directory
		def directory?
			!source.symlink? && source.directory?
		end

		def create_description
			if directory?
				"(directory)"
			else
				"-> #{link_target}"
			end
		end

		def type
			if directory?
				"Dir"
			else
				"File"
			end
		end


		############
		## Status ##
		############

		### Of the build

		def built?
			build.exist?
		end

		# The source has to be rebuilt (because it has been modified after it
		# was last built, or it doesn't exist)
		def outdated?
			# TODO skipped
			if    !built?    ; true    # Need rebuild because it does not exist
			elsif  directory?; false   # Existing directories are never outdated
			else             ; !@build.current?(@source)
			end
		end

		# The built file has been modified, i. e. we cannot rebuild it without
		# overwriting the changes
		def modified?
			# TODO skipped
			if    !built?     ; false # What has not been built cannot be modified
			elsif  directory? ; false # Directories are never modified
			else              ; !@build.file_identical?(@org)
			end
		end


		### Of the target

		# Whether the target already exists (file, directory or symlink)
		def target_exist?
			target.exist? || target.symlink?
		end

		# Whether the target is a proper directory
		def target_directory?
			target.directory? && !target.symlink?
		end

		# Whether the target for the entry is a symlink to the correct location
		def installed?
			if directory?
				# Directory entry: the target must be a directory
				target_directory?
			else
				# File entry: the target must be a symlink to the correct
				# location
				target.symlink? && target.readlink==link_target
			end
		end


		### Combined

		def build_status
			# TODO test
			# TODO skipped
			# The source file must exist, or the entry may not exist at all

			# File existence truth table:
			#
			# source | build | org || meaning
			# -------+-------+-----++---------------------------------------------------------
			# no     | -     | -   || Internal error - the entry should not exist
			# yes    | no    | -   || Not built (the org is irrelevant)
			# yes    | yes   | no  || Error: org missing (don't know if the user made changes)
			# yes    | yes   | yes || Built

			if    !@source.exist? ; return "Error"
			elsif !@build .exist? ; return "Not built"
			elsif !@org   .exist? ; return "org missing"
			# Otherwise: built. Check if current.
			else                  ; return "Built" # FIXME go on, check currency
			end

			# File currency truth table:
			#   * outdated: @build is older than @source
			#   * modified: @build is different from @org
			#
			# outdated | modified || meaning
			# ---------+----------++--------------------------
			# no       | no       || Current
			# no       | yes      || Modified (rebuild will overwrite) 
			# yes      | no       || Outdated (needs rebuild)
			# yes      | yes      || Modified (also outdated, but modified is more imporant to the user)

			if    modified? ; "Modified"
			elsif outdated? ; "Outdated"
			else            ; "Current"
			end
		end

		def target_status
			# TODO test
			# TODO skipped
			# Target status depends on @target
			if    installed?    ; "Installed"
			elsif target_exist? ; "Blocked"
			else                ; "Not installed"
			end
		end

		def status
			[type, build_status, target_status, unescape_path(path)]
		end

		def simple_status
			status.join(" ")
		end


		#############
		## Actions ##
		#############

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
			if !outdated? && !rebuild
				puts "#{MCurrent} #{build}" if @verbose
			else
				puts "#{MBuild} #{build}" if @verbose
				# The build file can be overwritten
				if directory?
					build.mkpath
					org  .mkpath
				else
					# Create the directory if it does not exist
					build.dirname.mkpath
					org.dirname.mkpath

					# TODO test dereferencing
					Builder.build source, build
					build.copy_file org
				end
			end
		end

		# Install the entry
		# * overwrite: If true, existing entries will be backed up and replaced.
		#   If false, existing entries will not be touched.
		def install!(overwrite)
			build! if (!built? || outdated?)

			if installed?
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

