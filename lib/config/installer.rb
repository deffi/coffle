require 'pathname'

module Config
	class Base
		include Filenames

		def initialize(source, target)
			@source=source.dup
			@target=target.dup

			# Convert to Pathname
			@source=Pathname.new(@source) unless @source.is_a?(Pathname)
			@target=Pathname.new(@target) unless @target.is_a?(Pathname)

			# Convert to absolute
			@source=@source.realpath
			@target=@target.realpath

			# Make sure they exist
			raise "Source directory #{@source} does not exist" if !@source.exist?
			raise "Target directory #{@target} does not exist" if !@target.exist?

			# Make sure they are directories
			raise "Source #{source} is not a directory" if !@source.directory?
			raise "Target #{target} is not a directory" if !@target.directory?

			@relative=@source.relative_path_from(@target)
		end

		def entries
			Dir["#{@source}/**/*"].reject { |dir|
				# Reject entries beginning with .
				dir =~ /^\./
			}.map { |dir|
				# Remove the source and any slashes from the beginning
				dir.gsub(/^#{@source}/, '').gsub(/^\/*/, '')
			}.map { |dir|
				# Create a (relative) pathname
				Pathname.new(dir)
			}
		end

		# The absolute path to the source (i. e. where the actual file is)
		def source_path(entry)
			@source.join entry
		end

		# The absolute path to the target (i. e. the config file location)
		def target_path(entry)
			@target.join unescape_path(entry)
		end

		# Whether the entry represents a directory
		def directory?(entry)
			source_path(entry).directory?
		end

		# Whether the target for the entry already exists
		def exist?(entry)
			target_path(entry).exist?
		end

		# The target the link should point to
		def link_target(entry)
			@relative.join entry
		end

		# Whether the target for the entry is a symlink to the correct location
		def current?(entry)
			if directory? entry
				# Directory entry
				target_path(entry).directory?
			else
				# File entry
				if target_path(entry).symlink?
					target_path(entry).readlink==link_target(entry)
				else
					false
				end
			end
		end
	end

	class Installer <Base
		MDir      ="Directory "
		MCreate   ="Creating  "
		MExist    ="Exists    "
		MCurrent  ="Current   "
		MOverwrite="Overwrite "

		def initialize(source, target)
			super
		end

		def remove!(entry)
		end

		def create!(entry)
			#puts "(not) Create link from #{target_path(entry)} to #{link_target(entry)}"
			target_path(entry).make_symlink link_target(entry)
		end

		# TODO Add backups
		# TODO Add remove
		def install(options={})
			puts "Installing from #{@source} to #{@target}"

			overwrite=options[:overwrite]

			entries.each do |entry|
				target=target_path(entry)

				if current? entry
					# target is already as it should be
					puts "#{MCurrent} #{target}"
				elsif exist?(entry)
					# target already exists
					# for now we assume that if the target already exists, it
					# has the correct type (directory/non-directory)
					if directory? entry
						# directory entry - no need to overwrite
						puts "#{MExist} #{target}"
					else
						if overwrite
							puts "#{MOverwrite} #{target}"
							remove!(entry)
							create!(entry)
						else
							puts "#{MExist} #{target}"
						end
					end
				else
					# target does not exist - create it
					puts "#{MCreate} #{target}"
					create! entry
				end
				#puts "#{source_path(entry)}\t\t#{target_path(entry)}"
			end
		end
	end
end

