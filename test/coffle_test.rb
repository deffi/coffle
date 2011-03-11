#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/test_helper.rb'

require 'coffle/pathname_extensions'

module Coffle
	class CoffleTest <Test::Unit::TestCase
		include TestHelper

		def test_coffle_directory
			with_testdir do |dir|
				source_dir=dir.join("source")
				target_dir=dir.join("target")

				# It does not exist
				assert_equal false, Coffle.coffle_source_directory?(source_dir)
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.assert_source_directory(source_dir) }
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.new(source_dir, target_dir) }

				# It's not a coffle source directory
				assert_equal false, Coffle.coffle_source_directory?(source_dir)
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.assert_source_directory(source_dir) }
				assert_raise(Exceptions::DirectoryIsNoCoffleSource) { Coffle.new(source_dir, target_dir) }

				# Make it a coffle source directory
				Coffle.initialize_source_directory!(source_dir)

				assert_equal true, Coffle.coffle_source_directory?(source_dir)
				assert_nothing_raised { Coffle.assert_source_directory(source_dir) }
				assert_nothing_raised { Coffle.new(source_dir, target_dir) }
			end
		end

		def test_paths
			with_testdir do |dir|
				assert dir.relative?

				# Create and initialize the source directory
				source_dir=dir.join("source")
				source_dir.mkdir
				Coffle.initialize_source_directory!(source_dir)

				# Create the Coffle
				coffle=Coffle.new("#{dir}/source", "#{dir}/target")

				# Absolute paths
				assert_equal "#{dir.absolute}/source"                     , coffle.source_dir.to_s
				assert_equal "#{dir.absolute}/source/.coffle"             , coffle.coffle_dir.to_s
				assert_equal "#{dir.absolute}/source/.coffle/work"        , coffle.work_dir  .to_s
				assert_equal "#{dir.absolute}/source/.coffle/work/output" , coffle.output_dir.to_s
				assert_equal "#{dir.absolute}/source/.coffle/work/org"    , coffle.org_dir   .to_s
				assert_equal "#{dir.absolute}/source/.coffle/work/backup" , coffle.backup_dir.to_s
				assert_equal "#{dir.absolute}/target"                     , coffle.target_dir.to_s
				#assert_match /^#{dir.absolute}\/source\/.backups\/\d\d\d\d-\d\d-\d\d_\d\d-\d\d-\d\d$/,
				#	                                                coffle.backup.to_s

				assert_equal "#{dir.absolute}/source/.coffle/work/status.yaml", coffle.status_file.to_s

				# The output and target directories must exist now (backup need not exist)
				assert_proper_directory coffle.source_dir
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
				source_dir=dir.join("source")

				source_dir.mkdir
				Coffle.initialize_source_directory!(source_dir)

				source_dir.join("_foo").touch
				source_dir.join("_bar").mkdir
				source_dir.join("_bar", "baz").touch
				source_dir.join(".ignore").touch # Must be ignored

				# Construct with relative paths and strings
				coffle=Coffle.new("#{dir}/source", "#{dir}/target")
				entries=coffle.entries.map { |entry| entry.path.to_s }

				# The number of entries must be correct
				assert_equal 3, entries.size

				# Entry paths are relative to the source directory
				assert_include "_foo", entries
				assert_include "_bar", entries
				assert_include "_bar/baz", entries
			end
		end

		def test_version
			with_testdir do |dir|
				source_dir=dir.join("source")
				target_dir=dir.join("target")

				config_file=Coffle.source_configuration_file(source_dir)
				assert_not_exist config_file

				# Initialize and check
				Coffle.initialize_source_directory!(source_dir)
				assert_equal true, Coffle.coffle_source_directory?(source_dir)
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
				assert_raise(Exceptions::CoffleVersionTooOld) { Coffle.new(source_dir, target_dir) }

				# Replace the version with something else, creating a Coffle instance must fail
				config["version"]=1.2
				config_file.write(config.to_yaml)
				assert_raise(Exceptions::SourceVersionIsNotInteger) { Coffle.new(source_dir, target_dir) }

				# Remove the version, creating a Coffle instance must fail
				config.delete "version"
				config_file.write(config.to_yaml)
				assert_raise(Exceptions::SourceVersionMissing) { Coffle.new(source_dir, target_dir) }

				# Write an array instead of a hash, creating a Coffle instance must fail
				config_file.write([].to_yaml)
				assert_raise(Exceptions::SourceConfigurationIsNotHash) { Coffle.new(source_dir, target_dir) }

				# Write a non-yaml file, creating a Coffle instance must fail
				config_file.write("\n:\n:")
				assert_raise(Exceptions::SourceConfigurationFileCorrupt) { Coffle.new(source_dir, target_dir) }

			end
		end
	end
end

