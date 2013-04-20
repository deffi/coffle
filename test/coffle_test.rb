#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

require 'coffle/pathname_extensions'

module Coffle
	class CoffleTest <Test::Unit::TestCase
		include TestHelper

		def test_coffle_directory
			with_testdir do |dir|
				repository_dir=dir.join("repository")
				target_dir    =dir.join("target")

				# It does not exist
				assert_equal false, Coffle.coffle_repository?(repository_dir)
				assert_raise(Exceptions::DirectoryIsNoRepository) { Coffle.assert_repository(repository_dir) }
				assert_raise(Exceptions::DirectoryIsNoRepository) { Coffle.new(repository_dir, target_dir) }

				# It's not a coffle repository
				assert_equal false, Coffle.coffle_repository?(repository_dir)
				assert_raise(Exceptions::DirectoryIsNoRepository) { Coffle.assert_repository(repository_dir) }
				assert_raise(Exceptions::DirectoryIsNoRepository) { Coffle.new(repository_dir, target_dir) }

				# Make it a coffle repository
				Coffle.initialize_repository!(repository_dir)

				assert_equal true, Coffle.coffle_repository?(repository_dir)
				assert_nothing_raised { Coffle.assert_repository(repository_dir) }
				assert_nothing_raised { Coffle.new(repository_dir, target_dir) }
			end
		end

		def test_paths
			with_testdir do |dir|
				assert dir.relative?

				# Create and initialize the repository
				repository_dir=dir.join("repository")
				repository_dir.mkdir
				Coffle.initialize_repository!(repository_dir)

				# Create the Coffle
				coffle=Coffle.new("#{dir}/repository", "#{dir}/target")

				# Absolute paths
				assert_equal "#{dir.absolute}/repository"                     , coffle.repository_dir.to_s
				assert_equal "#{dir.absolute}/repository/.coffle"             , coffle.coffle_dir    .to_s
				assert_equal "#{dir.absolute}/repository/.coffle/work"        , coffle.work_dir      .to_s
				assert_equal "#{dir.absolute}/repository/.coffle/work/output" , coffle.output_dir    .to_s
				assert_equal "#{dir.absolute}/repository/.coffle/work/org"    , coffle.org_dir       .to_s
				assert_equal "#{dir.absolute}/repository/.coffle/work/backup" , coffle.backup_dir    .to_s
				assert_equal "#{dir.absolute}/target"                     , coffle.target_dir    .to_s
				#assert_match /^#{dir.absolute}\/repository\/.backups\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d$/,
				#	                                                coffle.backup.to_s

				assert_equal "#{dir.absolute}/repository/.coffle/work/status.yaml", coffle.status_file.to_s

				# The output and target directories must exist now (backup need not exist)
				assert_proper_directory coffle.repository_dir
				assert_proper_directory coffle.coffle_dir
				assert_proper_directory coffle.work_dir
				assert_proper_directory coffle.output_dir
				assert_proper_directory coffle.org_dir
				assert_directory        coffle.target_dir

				# The backup direcory must not exist (only created when used)
				assert_not_present coffle.backup_dir

				# Writing of the status file
				# Note that the status file is written by run rather than the
				# individual actions (like install)
				assert_not_present coffle.status_file
				coffle.write_status
				assert_proper_file coffle.status_file
			end
		end

		def test_entries
			with_testdir do |dir|
				repository_dir=dir.join("repository")

				repository_dir.mkdir
				Coffle.initialize_repository!(repository_dir)

				repository_dir.join("_foo").touch
				repository_dir.join("_bar").mkdir
				repository_dir.join("_bar", "baz").touch
				repository_dir.join(".ignore").touch # Must be ignored

				# Construct with relative paths and strings
				coffle=Coffle.new("#{dir}/repository", "#{dir}/target")
				entries=coffle.entries.map { |entry| entry.path.to_s }

				# The number of entries must be correct
				assert_equal 3, entries.size

				# Entry paths are relative to the repository
				assert_include "_foo", entries
				assert_include "_bar", entries
				assert_include "_bar/baz", entries
			end
		end

		def test_version
			with_testdir do |dir|
				repository_dir=dir.join("repository")
				target_dir    =dir.join("target")

				config_file=Coffle.repository_configuration_file(repository_dir)
				assert_not_exist config_file

				# Initialize and check
				Coffle.initialize_repository!(repository_dir)
				assert_equal true, Coffle.coffle_repository?(repository_dir)
				assert_exist config_file

				# Check configuration
				config=YAML.load_file(config_file)
				assert config.is_a?(Hash)

				# Check version
				assert config.has_key?("version")
				assert config["version"].is_a?(Fixnum)

				# Increment version, creating a Coffle instance must fail
				config["version"]+=1
				config_file.write(config.to_yaml)
				assert_raise(Exceptions::CoffleVersionTooOld) { Coffle.new(repository_dir, target_dir) }

				# Replace the version with something else, creating a Coffle instance must fail
				config["version"]=1.2
				config_file.write(config.to_yaml)
				assert_raise(Exceptions::RepositoryVersionIsNotInteger) { Coffle.new(repository_dir, target_dir) }

				# Remove the version, creating a Coffle instance must fail
				config.delete "version"
				config_file.write(config.to_yaml)
				assert_raise(Exceptions::RepositoryVersionMissing) { Coffle.new(repository_dir, target_dir) }

				# Write an array instead of a hash, creating a Coffle instance must fail
				config_file.write([].to_yaml)
				assert_raise(Exceptions::RepositoryConfigurationIsNotHash) { Coffle.new(repository_dir, target_dir) }

				# Write a non-yaml file, creating a Coffle instance must fail
				config_file.write("\n:\n:")
				assert_raise(Exceptions::RepositoryConfigurationFileCorrupt) { Coffle.new(repository_dir, target_dir) }

			end
		end
	end
end

