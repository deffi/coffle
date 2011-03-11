require 'pathname'
require 'optparse'
require 'yaml'

require 'coffle/filenames'

module Coffle
	module Exceptions
		class DirectoryIsNoCoffleSource < Exception; end
		class CoffleVersionTooOld < Exception; end

		class SourceConfigurationReadError < Exception; end
		class SourceConfigurationFileCorrupt < SourceConfigurationReadError; end
		class SourceConfigurationIsNotHash < SourceConfigurationReadError; end
		class SourceVersionMissing < SourceConfigurationReadError; end
		class SourceVersionIsNotInteger < SourceConfigurationReadError; end
	end

	class Coffle
		include Filenames

		# Absolute
		attr_reader :source_dir, :coffle_dir, :work_dir, :output_dir, :org_dir, :target_dir, :backup_dir
		attr_reader :status_file

		class <<self
			attr_reader :source_version
		end
		@source_version=1

		# Calls path.mkpath and outputs a message if it did not exist before
		def create_directory (path)
			if !path.present?
				puts "Creating #{path}" if @verbose
				path.mkpath
			end
		end

		def self.source_configuration_file(directory)
			directory.join(".coffle_source.yaml")
		end

		def self.coffle_source_directory?(directory)
			source_configuration_file(directory).file?
		end

		def self.assert_source_directory(directory, msg=nil)
			if !coffle_source_directory?(directory)
				msg ||= "#{directory} is not a coffle source directory"
				raise Exceptions::DirectoryIsNoCoffleSource, msg
			end
		end

		def self.initialize_source_directory!(directory)
			configuration={"version"=>source_version}

			file=source_configuration_file(directory)
			file.dirname.mkpath
			file.write(configuration.to_yaml)
		end

		def read_source_configuration
			# Read the configuration
			begin
				@source_configuration=YAML.load(self.class.source_configuration_file(@source_dir).read)
			rescue ArgumentError
				raise Exceptions::SourceConfigurationFileCorrupt
			end
			raise Exceptions::SourceConfigurationIsNotHash unless @source_configuration.is_a?(Hash)

			# Extract values
			raise Exceptions::SourceVersionMissing unless @source_configuration.has_key?("version")
			source_dir_version=@source_configuration["version"]
			raise Exceptions::SourceVersionIsNotInteger unless source_dir_version.is_a?(Integer)

			# Make sure the version is new enough
			if source_dir_version>self.class.source_version
				msg="Source directory version is #{source_dir_version}, own source version is #{self.class.source_version}"
				raise Exceptions::CoffleVersionTooOld, msg
			end
		end

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize (source, target, options={})
			@verbose = options.fetch :verbose, false

			@source_dir=source.dup
			@target_dir=target.dup

			# Convert to Pathname
			@source_dir=Pathname.new(@source_dir) unless @source_dir.is_a?(Pathname)
			@target_dir=Pathname.new(@target_dir) unless @target_dir.is_a?(Pathname)

			# Make sure that the specified source directory is actually a
			# coffle source directory
			self.class.assert_source_directory @source_dir

			read_source_configuration

			@coffle_dir=@source_dir.join(".coffle")
			@work_dir  =@coffle_dir.join("work")
			@output_dir=@work_dir.join("output")
			@org_dir   =@work_dir.join("org")
			@backup_dir=@work_dir.join("backup")

			# Create the output and target directories if they don't exist
			create_directory @output_dir
			create_directory @org_dir
			create_directory @target_dir

			# Convert to absolute (the backup path need not exist, it
			# will be created when first used)
			# Not using realpath - backup need not exist
			@coffle_dir=@coffle_dir.absolute
			@work_dir  =@work_dir  .absolute
			@source_dir=@source_dir.absolute
			@output_dir=@output_dir.absolute
			@org_dir   =@org_dir   .absolute
			@target_dir=@target_dir.absolute
			@backup_dir=@backup_dir.absolute

			# Make sure they are directories
			raise "Source location #{@source_dir} is not a directory" if !@source_dir.directory?                     # Must exist
			raise "Output location #{@output_dir} is not a directory" if !@output_dir.directory?                     # Has been created
			raise "Target location #{@target_dir} is not a directory" if !@target_dir.directory?                     # Has been created
			raise "Backup location #{@backup_dir} is not a directory" if @backup_dir.present? && !@backup_dir.directory? # Must not be a non-directory

			# Files
			@status_file=@work_dir.join("status.yaml").absolute
			raise "Status file #{@status_file} is not a file" if @status_file.present? && !@status_file.file? # Must not be a non-file

			read_status
		end

		def entries
			if !@entries
				entries_status=@status_hash["entries"] || {}

				@entries = Dir["#{@source_dir}/**/*"].reject { |dir|
					# Reject entries beginning with .
					dir =~ /^\./
				}.map { |dir|
					# Remove the source and any slashes from the beginning
					dir.gsub(/^#{@source_dir}/, '').gsub(/^\/*/, '')
				}.map { |dir|
					# Create an entry with the (relative) pathname
					path=Pathname.new(dir)
					entry_status=entries_status[unescape_path(path).to_s]
					Entry.create(self, path, entry_status || {}, :verbose=>@verbose)
				}
			end

			@entries
		end

		def read_status
			if status_file.exist?
				@status_hash=YAML.load_file(status_file)
			else
				@status_hash={}
			end
		end

		def make_status
			entries_hash={}
			entries.each { |entry|
				entry_status_hash=entry.status_hash
				entries_hash[unescape_path(entry.path).to_s]=entry_status_hash
			}

			{"version"=>1, "entries"=>entries_hash}
		end

		def write_status
			status=make_status
			status_file.write status.to_yaml
		end

		def self.run(source, target, options)
			begin
				run!(source, target, options)
			rescue Exceptions::SourceConfigurationFileCorrupt => ex
				puts "Source configuration file corrupt"
			rescue Exceptions::CoffleVersionTooOld => ex
				puts "This version of coffle is too old for this source directory"
			rescue Exceptions::SourceConfigurationIsNotHash => ex
				puts "Source configuration file corrupt: not a hash"
			rescue Exceptions::SourceVersionMissing => ex
				puts "Source configuration file corrupt: version missing"
			rescue Exceptions::SourceVersionIsNotInteger => ex
				puts "Source configuration file corrupt: version not an integer"
			rescue Exceptions::SourceConfigurationReadError => ex
				puts "Source configuration file read error"
			rescue Exceptions::DirectoryIsNoCoffleSource => ex
				puts "#{source} is not a coffle source directory."
				puts "Use \"coffle init\" to initialize the directory."
			end
		end

		def self.run!(source, target, options)
			opts=OptionParser.new

			opts.banner = "Usage: #{$0} [options] action\n    action is one of build, install, uninstall, info, status, diff"

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
				return
			end

			action=ARGV[0]||""

			case action.downcase
				when "init"     : Coffle.init! source, options
				when "build"    : instance_action=:build
				when "install"  : instance_action=:install
				when "uninstall": instance_action=:uninstall
				when "info"     : instance_action=:info
				when "status"   : instance_action=:status
				when "diff"     : instance_action=:diff
				else puts opts # Output the options help message

			end

			if instance_action
				coffle=Coffle.new(source, target, options)

				case instance_action
				when :build    : coffle.build!     options
				when :install  : coffle.install!   options
				when :uninstall: coffle.uninstall! options
				when :info     : coffle.info!      options
				when :status   : coffle.status!    options
				when :diff     : coffle.diff!      options
				end

				coffle.write_status
			end
		end

		def self.init! (source_dir, options)
			source_dir=Pathname.new(source_dir) unless source_dir.is_a? Pathname

			if coffle_source_directory?(source_dir)
				puts "#{source_dir} is already a coffle source directory"
			else
				puts "Initializing coffle source directory #{source_dir}"
				initialize_source_directory!(source_dir)
			end
		end

		def build! (options={})
			rebuild  =options[:rebuild  ]
			overwrite=options[:overwrite]

			rebuilding =(rebuild  )?"rebuilding" :"non-rebuilding"
			overwriting=(overwrite)?"overwriting":"non-overwriting"

			puts "Building in #{@output_dir} (#{rebuilding}, #{overwriting})" if @verbose

			entries.each { |entry| entry.build rebuild, overwrite }
		end

		def install! (options={})
			overwrite=options[:overwrite]

			puts "Installing to #{@target_dir} (#{(overwrite)?"overwriting":"non-overwriting"})" if @verbose

			entries.each { |entry| entry.install overwrite }
		end

		def uninstall! (options={})
			puts "Uninstalling from #{@target_dir}" if @verbose

			entries.reverse.each { |entry| entry.uninstall }
		end

		def info! (options={})
			puts "Source: #{@source_dir}"
			puts "Target: #{@target_dir}"
			puts
			puts "Output: #{@output_dir}"
			puts "Org:    #{@org_dir}"
			puts "Backup: #{@backup_dir}"
		end

		def status! (options={})
			table=entries.map { |entry| entry.status }
			puts table.format_table("  ")
		end

		def diff! (options={})
			entries.each { |entry|
				if entry.modified?
					puts "="*80
					puts "== #{unescape_path(entry.path)} (#{entry.path})"
					puts "="*80
					org_label  ="original"
					output_label="modified"

					system "diff -u --label #{org_label} #{entry.org} --label #{output_label} #{entry.output}"
				end
			}
		end
	end
end

