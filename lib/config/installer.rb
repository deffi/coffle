require 'pathname'

class Pathname
	def absolute
		Pathname.getwd.join self
	end
end

module Config
	class Base
		# Absolute
		attr_accessor :source, :target, :backup

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize(source, target, backup, options={})
			@verbose = options.fetch :verbose, false

			@source=source.dup
			@target=target.dup
			@backup=backup.dup

			# Convert to Pathname
			@source=Pathname.new(@source) unless @source.is_a?(Pathname)
			@target=Pathname.new(@target) unless @target.is_a?(Pathname)
			@backup=Pathname.new(@backup) unless @backup.is_a?(Pathname)

			# Make sure the source directory exists
			raise "Source directory #{@source} does not exist" if !@source.exist?

			# Create the target if does not exist
			if !@target.exist?
				puts "Creating #{@target}" if @verbose
				@target.mkpath unless @target.exist?
			end

			# Convert to absolute (the backup path need not exist, it
			# will be created when first used)
			# Not using realpath - backup need not exist
			@source=@source.absolute
			@target=@target.absolute
			@backup=@backup.absolute

			# Make sure they are directories
			raise "Source #{source} is not a directory" if !@source.directory?
			raise "Target #{target} is not a directory" if !@target.directory?
			raise "Backup location #{backup} is not a directory" if @backup.exist? && !@backup.directory?
		end

		def entries
			Dir["#{@source}/**/*"].reject { |dir|
				# Reject entries beginning with .
				dir =~ /^\./
			}.map { |dir|
				# Remove the source and any slashes from the beginning
				dir.gsub(/^#{@source}/, '').gsub(/^\/*/, '')
			}.map { |dir|
				# Create an entry with the (relative) pathname
				Entry.new(self, Pathname.new(dir), :verbose=>@verbose)
			}
		end
	end

	class Installer <Base
		def initialize(source, target, backup, options={})
			super
		end

		def install(options={})
			overwrite=options[:overwrite]

			puts "Installing from #{@source} to #{@target} (#{(overwrite)?"overwriting":"non-overwriting"})" if @verbose

			entries.each do |entry|
				entry.install! overwrite
			end
		end
	end
end

