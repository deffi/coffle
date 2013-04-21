require 'coffle/coffle'

module Coffle
	# Basically, the command line interface to coffle
	class Runner
		def initialize(repository, target, options)
			@repository=repository
			@target=target
			@options=options
		end

		def run
			begin
				run!
			rescue Exceptions::RepositoryConfigurationFileCorrupt => ex
				puts "Repository configuration file corrupt"
			rescue Exceptions::CoffleVersionTooOld => ex
				puts "This version of coffle is too old for this repository"
			rescue Exceptions::RepositoryConfigurationIsNotHash => ex
				puts "Repository configuration file corrupt: not a hash"
			rescue Exceptions::RepositoryVersionMissing => ex
				puts "Repository configuration file corrupt: version missing"
			rescue Exceptions::RepositoryVersionIsNotInteger => ex
				puts "Repository configuration file corrupt: version not an integer"
			rescue Exceptions::RepositoryConfigurationReadError => ex
				puts "Repository configuration file read error"
			rescue Exceptions::DirectoryIsNoRepository => ex
				puts "#{@repository} is not a coffle repository."
				puts "Use \"coffle init\" to initialize the directory."
			end
		end

		# Performs no exception checking
		def run!
			opts=OptionParser.new

			opts.banner = "Usage: #{$0} [options] action\n    action is one of init, build, install, uninstall, info, status, diff"

			opts.separator ""
			opts.separator "install options:"

			opts.on("-o", "--[no-]overwrite", "Overwrite existing files (a backup will be created)") { |v| @options[:overwrite] = v }

			opts.separator ""
			opts.separator "build options:"

			opts.on("-r", "--[no-]rebuild", "Build even if the built file is current") { |v| @options[:rebuild] = v }

			opts.separator ""
			opts.separator "Common options:"

			opts.on("-h", "--help"   , "Show this message") { puts opts   ; exit }
			opts.on(      "--version", "Show version"     ) { puts VERSION; exit }

			begin
				opts.parse!
			rescue OptionParser::InvalidOption => ex
				puts ex.message
				return
			end

			action=ARGV[0]||""

			case action.downcase
				when "init"     then Coffle.init! @repository, @options
				when "build"    then instance_action=:build
				when "install"  then instance_action=:install
				when "uninstall"then instance_action=:uninstall
				when "info"     then instance_action=:info
				when "status"   then instance_action=:status
				when "diff"     then instance_action=:diff
				else puts opts # Output the options help message

			end

			if instance_action
				coffle=Coffle.new(@repository, @target, @options)

				case instance_action
				when :build     then coffle.build!     @options
				when :install   then coffle.install!   @options
				when :uninstall then coffle.uninstall! @options
				when :info      then coffle.info!      @options
				when :status    then coffle.status!    @options
				when :diff      then coffle.diff!      @options
				end

				coffle.write_status
				coffle.write_target_status
			end
		end
	end
end

