require 'pathname'
require 'optparse'
require 'yaml'

require 'coffle/filenames'
require 'coffle/exceptions'

module Coffle
	class Coffle
		include Filenames

		# Absolute
		attr_reader :repository_dir, :coffle_dir, :work_dir, :output_dir, :org_dir, :target_dir, :backup_dir
		attr_reader :status_file

		class <<self
			attr_reader :repository_version
		end
		@repository_version=1

		def self.repository_configuration_file(directory)
			# The repository used to be called "source directory", but that's
			# misleading. The file is still called .coffle_source.yaml.
			# Renaming it will introduce some legacy code to recognize and
			# upgrade old repositories.
			directory.join(".coffle_source.yaml")
		end

		def self.coffle_repository?(directory)
			repository_configuration_file(directory).file?
		end

		def self.assert_repository(directory, msg=nil)
			if !coffle_repository?(directory)
				msg ||= "#{directory} is not a coffle repository"
				raise Exceptions::DirectoryIsNoRepository, msg
			end
		end

		def self.initialize_repository!(directory)
			configuration={"version"=>repository_version}

			file=repository_configuration_file(directory)
			file.dirname.mkpath
			file.write(configuration.to_yaml)
		end

		def read_repository_configuration
			# Read the configuration
			begin
				@repository_configuration=YAML.load(self.class.repository_configuration_file(@repository_dir).read)
			rescue ArgumentError
				raise Exceptions::RepositoryConfigurationFileCorrupt
			rescue Psych::SyntaxError
				raise Exceptions::RepositoryConfigurationFileCorrupt
			end
			raise Exceptions::RepositoryConfigurationIsNotHash unless @repository_configuration.is_a?(Hash)

			# Extract values
			raise Exceptions::RepositoryVersionMissing unless @repository_configuration.has_key?("version")
			repository_version=@repository_configuration["version"]
			raise Exceptions::RepositoryVersionIsNotInteger unless repository_version.is_a?(Integer)

			# Make sure the version is new enough
			if repository_version>self.class.repository_version
				msg="Repository version is #{repository_version}, own repository version is #{self.class.repository_version}"
				raise Exceptions::CoffleVersionTooOld, msg
			end
		end

		# Options:
		# * :verbose: print messages; recommended for interactive applications
		def initialize (repository, target, options={})
			@verbose = options.fetch :verbose, false

			# Use absolute paths for the directories. Do not use realpath
			# because some of the directories might not exist at this point.
			@repository_dir=repository.to_pathname.absolute
			@target_dir=target.to_pathname.absolute

			# Make sure that the specified repository directory is actually a
			# coffle repository directory
			Coffle.assert_repository @repository_dir
			read_repository_configuration

			# Create the target directory
			@target_dir.mkpath

			# Resolve symlinks in the repository and target directories
			@repository_dir=@repository_dir.realpath
			@target_dir=@target_dir.realpath

			# Create the pathnames for the subdirectories. This may depend on
			# the repository directory configuration.
			@coffle_dir=@repository_dir.join(".coffle")
			@work_dir  =@coffle_dir.join("work")
			@output_dir=@work_dir  .join("output")
			@org_dir   =@work_dir  .join("org")
			@backup_dir=@work_dir  .join("backup")

			# Create some of the directories if they don't exist yet
			@output_dir.mkpath
			@org_dir   .mkpath

			# Make sure they are directories
			raise "Repository location #{@repository_dir} is not a directory" if !@repository_dir.directory?     # Must exist
			raise "Target     location #{@target_dir    } is not a directory" if !@target_dir    .directory?     # Has been created
			raise "Coffle     location #{@coffle_dir    } is not a directory" if !@coffle_dir    .directory?     # Has been created
			raise "Work       location #{@work_dir      } is not a directory" if !@work_dir      .directory?     # Has been created
			raise "Output     location #{@output_dir    } is not a directory" if !@output_dir    .directory?     # Has been created
			raise "Output     location #{@org_dir       } is not a directory" if !@org_dir       .directory?     # Has been created
			raise "Backup     location #{@backup_dir    } is not a directory" if  @backup_dir    .non_directory? # Must not be a non-directory

			# Files
			@status_file=@work_dir.join("status.yaml")
			raise "Status file #{@status_file} is not a file" if @status_file.non_file? # Must not be a non-file

			read_status
		end

		def entries
			if !@entries
				entries_status=@status_hash["entries"] || {}

				@entries=Dir["#{@repository_dir}/**/*"].reject { |dir|
					# Reject entries beginning with .
					dir =~ /^\./
				}.map { |dir|
					# Remove the repository and any slashes from the beginning
					dir.gsub(/^#{@repository_dir}/, '').gsub(/^\/*/, '')
				}.map { |dir|
					# Create an entry with the (relative) pathname
					path=Pathname.new(dir)
					entry_status=entries_status[unescape_path(path).to_s]
					Entry.create(self, path, entry_status || {}, :verbose=>@verbose)
				}
			end

			@entries
		end


		############
		## Status ##
		############

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


		###################
		## Target status ##
		###################

		def write_target_status
			if target_dir.exist?
				target_status_file=target_dir.join('.coffle_target.yaml')

				target_status={
					"version"=>1
				}

				target_status_file.write(target_status.to_yaml)
			end
		end


		#############
		## Actions ##
		#############

		def self.init! (repository_dir, options)
			repository_dir=Pathname.new(repository_dir) unless repository_dir.is_a? Pathname

			if coffle_repository?(repository_dir)
				puts "#{repository_dir} is already a coffle repository"
			else
				puts "Initializing coffle repository #{repository_dir}"
				initialize_repository!(repository_dir)
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
			puts "Repository: #{@repository_dir}"
			puts "Target:     #{@target_dir}"
			puts
			puts "Output:     #{@output_dir}"
			puts "Org:        #{@org_dir}"
			puts "Backup:     #{@backup_dir}"
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

