require 'coffle/coffle'

module Coffle
	# Basically, the command line interface to coffle
	class Runner
		def initialize(source, target, options)
			@source=source
			@target=target
			@options=options
		end

		def run
			begin
				run!
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
				puts "#{@source} is not a coffle source directory."
				puts "Use \"coffle init\" to initialize the directory."
			end
		end

		# Performs no exception checking
		def run!
			opts=OptionParser.new

			opts.banner = "Usage: #{$0} [options] action\n    action is one of build, install, uninstall, info, status, diff"

			opts.separator ""
			opts.separator "install options:"

			opts.on("-o", "--[no-]overwrite", "Overwrite existing files (a backup will be created)") { |v| @options[:overwrite] = v }

			opts.separator ""
			opts.separator "build options:"

			opts.on("-r", "--[no-]rebuild", "Build even if the built file is current") { |v| @options[:rebuild] = v }

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
				when "init"     : Coffle.init! @source, @options
				when "build"    : instance_action=:build
				when "install"  : instance_action=:install
				when "uninstall": instance_action=:uninstall
				when "info"     : instance_action=:info
				when "status"   : instance_action=:status
				when "diff"     : instance_action=:diff
				else puts opts # Output the options help message

			end

			if instance_action
				coffle=Coffle.new(@source, @target, @options)

				case instance_action
				when :build    : coffle.build!     @options
				when :install  : coffle.install!   @options
				when :uninstall: coffle.uninstall! @options
				when :info     : coffle.info!      @options
				when :status   : coffle.status!    @options
				when :diff     : coffle.diff!      @options
				end

				coffle.write_status
				coffle.write_target_status
			end
		end
	end
end

