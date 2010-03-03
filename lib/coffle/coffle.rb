require 'pathname'
require 'optparse'


module Coffle
	class Coffle
		# Absolute
		attr_accessor :source, :build, :target, :backup

		def create_directory(path)
			if !path.exist?
				puts "Creating #{path}" if @verbose
				path.mkpath
			end
		end

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize(source, target, options={})
			@verbose = options.fetch :verbose, false

			@source=source.dup
			@target=target.dup

			# Convert to Pathname
			@source=Pathname.new(@source) unless @source.is_a?(Pathname)
			@target=Pathname.new(@target) unless @target.is_a?(Pathname)

			@build =@source.join(".build")
			@backup=@source.join(".backups/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}")

			# Make sure the source directory exists
			raise "Source directory #{@source} does not exist" if !@source.exist?

			# Create the build and target directories if they don't exist
			create_directory @build
			create_directory @target

			# Convert to absolute (the backup path need not exist, it
			# will be created when first used)
			# Not using realpath - backup need not exist
			@source=@source.absolute
			@build =@build .absolute
			@target=@target.absolute
			@backup=@backup.absolute

			# Make sure they are directories
			raise "Source location #{source} is not a directory" if !@source.directory?
			raise "Build location #{ build } is not a directory" if !@build .directory?
			raise "Target location #{target} is not a directory" if !@target.directory?
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

		def run
			options = {}
			opts=OptionParser.new

			opts.banner = "Usage: #{$0} [options] action\n    action is one of install, build"

			opts.separator ""
			opts.separator "install options:"

			opts.on("-o", "--[no-]overwrite", "Overwrite existing files (a backup will be created)") { |v| options[:overwrite] = v }

			opts.separator ""
			opts.separator "build options:"

			opts.on("-r", "--[no-]rebuild", "Build even if the built file is current") { |v| options[:rebuild] = v }

			opts.separator ""
			opts.separator "Common options:"

			opts.on("-h", "--help"   , "Show this message") { puts opts           ; exit }
			opts.on(      "--version", "Show version"     ) { puts Coffle::VERSION; exit }

			begin
				opts.parse!
			rescue OptionParser::InvalidOption => ex
				puts ex.message
			end

			action=ARGV[0]

			case action
			when /build/i: build! options
			when /install/i: install! options
			else puts opts
			end
		end

		def install!(options={})
			overwrite=options[:overwrite]

			puts "Installing to #{@target} (#{(overwrite)?"overwriting":"non-overwriting"})" if @verbose

			entries.each { |entry| entry.install! overwrite }
		end

		def build!(options={})
			rebuild=options[:rebuild]

			puts "Building in #{@build} (#{(rebuild)?"rebuilding":"non-rebuilding"})" if @verbose

			entries.each { |entry| entry.build! rebuild }
		end
	end
end

