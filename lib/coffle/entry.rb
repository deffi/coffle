require 'pathname'

require 'coffle/filenames'
require 'coffle/messages'

module Coffle
	class Entry
		include Filenames
		include Messages

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
		# TODO can we make the constructor protected?
		def initialize(coffle, path, options={})
			@path=path

			@verbose = options.fetch :verbose, false

			@source=coffle.source.join @path # The absolute path to the source (i. e. the template)
			@build =coffle.build .join @path # The absolute path to the built file
			@org   =coffle.org   .join @path # The absolute path to the original of the built file
			@target=coffle.target.join unescape_path(@path) # The absolute path to the target (i. e. the config file location)
			@backup=coffle.backup.join unescape_path(@path) # The absolute path to the backup file

			# The target the link should point to
			@link_target=build.relative_path_from(target.dirname)
		end


		################
		## Properties ##
		################

		# Entry factory method
		def Entry.create(coffle, path, options={})
			source_path=coffle.source.join(path) # TODO code duplication

			if    source_path.proper_file?     ; FileEntry     .new(coffle, path, options)
			elsif source_path.proper_directory?; DirectoryEntry.new(coffle, path, options)
			else  nil
			end
		end


		############
		## Status ##
		############

		### Of the build

		def built?
			build.exist?
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
			if    installed?      ; "Installed"
			elsif target.present? ; "Blocked"
			else                  ; "Not installed"
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


		def build!(rebuild=false, overwrite=false)
			# Note that if the entry is modified and overwrite is true, it
			# is rebuilt even if it is current.

			if modified?
				# Build modified by the user
				if overwrite
					# Overwrite the modifications
					do_build!
				else
					# Do not overwrite
					puts "#{MModified} #{build}" if @verbose
				end
			elsif outdated? || rebuild
				# Outdated (source changed)
				do_build!
			else
				# Current
				puts "#{MCurrent} #{build}" if @verbose
			end
		end

		# Returns true if the entry is now uninstalled (even if nothing had to
		# be done)
		#def uninstall!
		#	# FIXME implement
		#	if !installed?
		#		puts "#{MNotInstalled}" if @verbose
		#		true
		#	elsif directory?
		#	else
		#		if backup.present?
		#			# No backup present, nothing to restore
		#		else
		#			# Need to restore the backup
		#		end
		#	end
		#end

		# Install the entry
		# * overwrite: If true, existing entries will be backed up and replaced.
		#   If false, existing entries will not be touched.
		# Returns true if the entry is now installed (even if nothing had to
		# be done)
		def install!(overwrite)
			build! if (!built? || outdated?)

			if installed?
				# Nothing to do
				puts "#{MCurrent} #{target}" if @verbose
				true
			elsif backup.present?
				# The entry is not installed, but the backup exists. This
				# should not happen - the user messed it up. Refuse.
				puts "#{MBackupExists} #{target}" if @verbose
				false
			elsif target.present?
				# Target already exists and is not current (i. e. for
				# directory entries, the target is not a directory,
				# and for file entries it is not a symlink to the
				# correct position)
				if blocked_by?(target)
					# Refuse
					puts "#{MBlocked} #{target}" if @verbose
					false
				else
					# The target type matches the entry type
					# Note that this must be a file because a directory would
					# have been recognized as installed.
					raise "Internal error: directory exists" if target.directory?

					if overwrite
						puts "#{MOverwrite} #{target} #{create_description} (backup in #{backup})" if @verbose
						remove!
						create!
						true
					else
						puts "#{MExist} #{target} (not overwriting)" if @verbose
						false
					end
				end

			else
				# Target does not exist - create it
				puts "#{MCreate} #{target} #{create_description}" if @verbose
				create!
				true
			end
		end
	end
end

