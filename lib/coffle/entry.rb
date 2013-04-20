require 'pathname'

require 'coffle/filenames'
require 'coffle/messages'

module Coffle
	# An entry can either be built or skipped. Everything else is inconsistent.
	class Entry
		include Filenames
		include Messages

		################
		## Attributes ##
		################

		# The relative path
		attr_reader :path

		# Absolute paths to entries
		attr_reader :source, :output, :org, :target, :backup

		# Relative link target from target to output
		attr_reader :link_target

		# Status
		def skipped?; @skipped; end
		attr_reader :timestamp


		##################
		## Construction ##
		##################

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize(coffle, path, status, options)
			@path=path

			@skipped=status["skipped"]
			@timestamp=status["timestamp"]

			@verbose = options.fetch :verbose, false

			@source=coffle.repository_dir.join @path # The absolute path to the source (i. e. the template)
			@output=coffle.output_dir    .join unescape_path(@path) # The absolute path to the built file
			@org   =coffle.org_dir       .join unescape_path(@path) # The absolute path to the original of the built file
			@target=coffle.target_dir    .join unescape_path(@path) # The absolute path to the target (i. e. the config file location)
			@backup=coffle.backup_dir    .join unescape_path(@path) # The absolute path to the backup file

			# The target the link should point to
			@link_target=output.relative_path_from(target.dirname)
		end

		# Make sure the constructor cannot be called except from Entry
		class <<self
			protected :new
		end

		# Entry factory method
		def Entry.create(coffle, path, status, options)
			source_path=coffle.repository_dir.join(path)

			if    source_path.proper_file?     ; FileEntry     .new(coffle, path, status, options)
			elsif source_path.proper_directory?; DirectoryEntry.new(coffle, path, status, options)
			else  nil
			end
		end


		############
		## Status ##
		############

		def status_hash
			result={}
			result["skipped"  ]=true       if @skipped
			result["timestamp"]=@timestamp if @timestamp
			result unless result.empty?
		end

		# Only valid if built
		#def effective_timestamp
		#	if built?
		#		org.mtime
		#	elsif skipped
		#		@timestamp
		#	else
		#		raise "inconsistent"
		#	end
		#end

		def output_status
			# File existence truth table:
			#
			# source | skipped | output | org || meaning
			# -------+---------+--------+-----++---------------------------------------------------------
			# no     | -       | -      | -   || Internal error - this entry should not exist
			# yes    | yes     | no     | -   || Skipped
			# yes    | no      | no     | -   || Not built (the org is irrelevant)
			# yes    | no      | yes    | no  || Error: org missing (don't know if the user made changes)
			# yes    | no      | yes    | yes || Built

			if    !source.exist? ; return "Error"
			elsif skipped?       ; return "Skipped"
			elsif !output.exist? ; return "Not built"
			elsif !org   .exist? ; return "org missing"
			# Otherwise: built. Check if current.
			end

			# File currency truth table:
			#   * outdated: output is older than source
			#   * modified: output is different from org
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
			# Target status depends on target
			if    installed?      ; "Installed"
			elsif target.present? ; "Blocked"
			else                  ; "Not installed"
			end
		end

		def status
			[type, output_status, target_status, unescape_path(path)]
		end

		def simple_status
			status.join(" ")
		end


		#######################
		## Front-end actions ##
		#######################

		def do_build
			build!

			if skipped?
				message "#{MSkipped} #{output}"
				uninstall if installed?
			else
				message "#{MBuilt} #{output}"
			end
		end

		# Build the entry, that is, create the output in the output directory
		def build(rebuild=false, overwrite=false)
			# Note that if the entry is modified and overwrite is true, it
			# is rebuilt even if it is current.

			# Note that we do not check for built? - if the file is neither
			# built nor skipped, it will be caught by oudated?
			if modified?
				# Output modified by the user
				if overwrite
					# Overwrite the modifications
					do_build
				else
					# Do not overwrite
					message "#{MModified} #{output}"
				end
			elsif outdated? || rebuild
				# Outdated (source changed), or forced rebuild
				do_build
			else
				# Current
				message "#{MCurrent} #{output}"
			end
		end

		# Install the entry
		# * overwrite: If true, existing entries will be backed up and replaced.
		#   If false, existing entries will not be touched.
		# Returns true if the entry is now installed (even if nothing had to
		# be done)
		def install(overwrite)
			if outdated?
				build # non-rebuilding, non-overwriting
			end

			if skipped?
				# Skipped entries are not installed
				message "#{MSkipped} #{target}"
				true
			elsif installed?
				# Nothing to do
				message "#{MCurrent} #{target}"
				true
			elsif backup.present?
				# The entry is not installed, but there is a backup, which
				# means that the entry was installed once. This should not
				# happen - the user either replaced or removed the installed
				# entry.
				if target.present?
					# Target was replaced. Refuse.
					message "#{MReplaced} #{target}"
					false
				else
					# Target was removed. Restore.
					message "#{MRestored} #{target}"
					install!
					true
				end
			elsif !target.present?
				# Regular install
				message "#{MInstall} #{target} #{create_description}"
				install!
				true
			else
				# Target already exists, but is not installed (i. e. for
				# directory entries, the target is not a directory, and for
				# file entries it is not a symlink to the correct position)
				if blocked_by?(target)
					# It's not possible to install the entry. Refuse.
					message "#{MBlocked} #{target}"
					false
				else
					# The target type matches the entry type
					if overwrite
						message "#{MOverwrite} #{target} #{create_description} (backup in #{backup})"
						install_overwrite!
						true
					else
						message "#{MExist} #{target} (not overwriting)"
						false
					end
				end
			end
		end

		# Returns true if the entry is now uninstalled (even if nothing had to
		# be done)
		def uninstall
			if installed?
				message "#{MUninstall} #{target}"
				uninstall!
				true
			elsif backup.present?
				if target.present?
					message "#{MReplaced} #{target}"
				else
					message "#{MRemoved} #{target}"
				end
				false
			else
				message "#{MNotInstalled} #{target}"
				true
			end
		end

		def outdate
			@timestamp=source.mtime-1 if @timestamp
			output.set_older source if output.present?
			org   .set_older source if org   .present?
		end


		##########
		## Misc ##
		##########

		def message(m)
			puts m if @verbose
		end
	end
end

