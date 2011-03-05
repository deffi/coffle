require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class EntryTest <Test::Unit::TestCase
		include TestHelper

		# TODO also compare file contents
		# TODO also test uninstall
		# TODO dir blocked by invalid symlink - not handled properly
		def test_full
			with_testdir do |dir|
				# source          in actual/source
				# target          in actual/target
				# expected source in expected/source (containing .output)
				# expected target in expected/target
				actual  =dir.join("actual"  ).absolute; actual  .mkpath
				expected=dir.join("expected").absolute; expected.mkpath


				##### Create the actual directory


				# Source
				actual.join("source").mkpath                         # source
				actual.join("source", ".coffle").mkpath              # |
				actual.join("source", "_reg_file").touch             # |-.reg_file   - Regular file
				actual.join("source", "_reg_dir").mkdir              # |-.reg_dir    - Regular directory
				actual.join("source", "_reg_dir", "reg_file").touch  # | '-reg_file  - Regular file in directory
				actual.join("source", "_ex_file").touch              # |-.ex_file    - Existing file
				actual.join("source", "_ex_dir").mkdir               # |-.ex_dir     - Existing directory
				actual.join("source", "_ex_dir", "ex_file").touch    # | '-ex_file   - Existing file in directory
				actual.join("source", "_link_dir").mkdir             # '-.link_dir   - Existing symlinked directory
				actual.join("source", "_link_dir", "ex_file").touch  #   '-ex_file   - Existing file in symlinked directory


				# Target (already existing)
				actual.join("target").mkpath                                        # target
				actual.join("target", ".ex_file").touch                             # |-.ex_file
				actual.join("target", ".ex_dir").mkdir                              # |-.ex_dir
				actual.join("target", ".ex_dir", "ex_file").touch                   # | |-ex_file
				actual.join("target", ".ex_dir", "other_file").touch                # | '-other_file                   # Other file in existing directory
				actual.join("target", ".link_dir").make_symlink(".link_dir_target") # |-.link_dir -> .link_dir_target  # The symlinked directory
				actual.join("target", ".link_dir_target").mkpath                    # '-.link_dir_target               # The symlinked directory target
				actual.join("target", ".link_dir_target", "ex_file").touch          #   |-ex_file
				actual.join("target", ".link_dir_target", "other_file").touch       #   '-other_file                   # Other file in symlinked directory


				##### Created the expected directory

				# Source - same as actual
				FileUtils.cp_r actual.join("source").to_s, expected.join("source").to_s

				# Output
				expected.join("source", ".output").mkpath
				expected.join("source", ".output", "_reg_file"            ).touch
				expected.join("source", ".output", "_reg_dir"             ).mkdir
				expected.join("source", ".output", "_reg_dir", "reg_file" )  .touch
				expected.join("source", ".output", "_ex_file"             ).touch
				expected.join("source", ".output", "_ex_dir"              ).mkdir
				expected.join("source", ".output", "_ex_dir", "ex_file"   )  .touch
				expected.join("source", ".output", "_link_dir"            ).mkdir
				expected.join("source", ".output", "_link_dir", "ex_file" )  .touch

				# Org
				expected.join("source", ".output", ".org").mkpath
				expected.join("source", ".output", ".org", "_reg_file"            ).touch
				expected.join("source", ".output", ".org", "_reg_dir"             ).mkdir
				expected.join("source", ".output", ".org", "_reg_dir", "reg_file" )  .touch
				expected.join("source", ".output", ".org", "_ex_file"             ).touch
				expected.join("source", ".output", ".org", "_ex_dir"              ).mkdir
				expected.join("source", ".output", ".org", "_ex_dir", "ex_file"   )  .touch
				expected.join("source", ".output", ".org", "_link_dir"            ).mkdir
				expected.join("source", ".output", ".org", "_link_dir", "ex_file" )  .touch

				# Backup
				expected.join("source", ".backup").mkpath
				expected.join("source", ".backup", ".ex_file"             ).touch
				expected.join("source", ".backup", ".ex_dir"              ).mkdir
				expected.join("source", ".backup", ".ex_dir", "ex_file"   )  .touch
				expected.join("source", ".backup", ".link_dir"            ).mkdir
				expected.join("source", ".backup", ".link_dir", "ex_file" )  .touch
 
				# Target
				expected.join("target").mkpath
				expected.join("target", ".reg_file"                     ).make_symlink("../source/.output/_reg_file")
				expected.join("target", ".reg_dir"                      ).mkdir
				expected.join("target", ".reg_dir", "reg_file"          )  .make_symlink("../../source/.output/_reg_dir/reg_file")
				expected.join("target", ".ex_file"                      ).make_symlink("../source/.output/_ex_file")
				expected.join("target", ".ex_dir"                       ).mkdir
				expected.join("target", ".ex_dir", "ex_file"            )  .make_symlink("../../source/.output/_ex_dir/ex_file")
				expected.join("target", ".ex_dir", "other_file"         )  .touch
				expected.join("target", ".link_dir"                     ).make_symlink(".link_dir_target")
				expected.join("target", ".link_dir_target"              ).mkpath
				expected.join("target", ".link_dir_target", "ex_file"   )  .make_symlink("../../source/.output/_link_dir/ex_file")
				expected.join("target", ".link_dir_target", "other_file")  .touch


				##### Create the coffle (also creates the output and target directories)
				coffle=Coffle.new("#{dir}/actual/source", "#{dir}/actual/target")

				coffle.entries.each do |entry|
					entry.build
					entry.install(true)
				end

				assert_tree_equal(expected, actual)
				#p expected.tree_entries
			end
		end
	end
end


