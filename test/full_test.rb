require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class FullTest <Test::Unit::TestCase
		include TestHelper

		def test_full
			with_testdir do |dir|
				# source                                        in actual/source
				# target                                        in actual/target
				# expected directories for after installation   in expected_install/
				# expected directories for after uninstallation in expected_uninstall/
				actual            =dir.join("actual"            ).absolute; actual            .mkpath
				expected_install  =dir.join("expected_install"  ).absolute; expected_install  .mkpath
				expected_uninstall=dir.join("expected_uninstall").absolute; expected_uninstall.mkpath


				##### Create the coffle (also creates the output and target directories)
				actual.join("source", ".coffle").mkpath
				coffle=Coffle.new("#{dir}/actual/source", "#{dir}/actual/target")


				##### Create the actual directory

				# Source
				actual.join("source").mkpath                         # source
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
				actual.join("target", ".ex_dir", "other_file").touch                # | '-other_file                   - Other file in existing directory
				actual.join("target", ".link_dir").make_symlink(".link_dir_target") # |-.link_dir -> .link_dir_target  - The symlinked directory
				actual.join("target", ".link_dir_target").mkpath                    # '-.link_dir_target               - The symlinked directory target
				actual.join("target", ".link_dir_target", "ex_file").touch          #   |-ex_file
				actual.join("target", ".link_dir_target", "other_file").touch       #   '-other_file                   - Other file in symlinked directory


				##### Create the expected_install directory

				# Source - same as actual
				FileUtils.cp_r actual.join("source").to_s, expected_install.join("source").to_s

				# Output
				expected_install.join("source", ".coffle", "work", "output").mkpath
				expected_install.join("source", ".coffle", "work", "output", "_reg_file"            ).touch
				expected_install.join("source", ".coffle", "work", "output", "_reg_dir"             ).mkdir
				expected_install.join("source", ".coffle", "work", "output", "_reg_dir", "reg_file" )  .touch
				expected_install.join("source", ".coffle", "work", "output", "_ex_file"             ).touch
				expected_install.join("source", ".coffle", "work", "output", "_ex_dir"              ).mkdir
				expected_install.join("source", ".coffle", "work", "output", "_ex_dir", "ex_file"   )  .touch
				expected_install.join("source", ".coffle", "work", "output", "_link_dir"            ).mkdir
				expected_install.join("source", ".coffle", "work", "output", "_link_dir", "ex_file" )  .touch

				# Org
				expected_install.join("source", ".coffle", "work", "org").mkpath
				expected_install.join("source", ".coffle", "work", "org", "_reg_file"            ).touch
				expected_install.join("source", ".coffle", "work", "org", "_reg_dir"             ).mkdir
				expected_install.join("source", ".coffle", "work", "org", "_reg_dir", "reg_file" )  .touch
				expected_install.join("source", ".coffle", "work", "org", "_ex_file"             ).touch
				expected_install.join("source", ".coffle", "work", "org", "_ex_dir"              ).mkdir
				expected_install.join("source", ".coffle", "work", "org", "_ex_dir", "ex_file"   )  .touch
				expected_install.join("source", ".coffle", "work", "org", "_link_dir"            ).mkdir
				expected_install.join("source", ".coffle", "work", "org", "_link_dir", "ex_file" )  .touch

				# Backup
				expected_install.join("source", ".coffle", "work", "backup").mkpath
				expected_install.join("source", ".coffle", "work", "backup", ".ex_file"             ).touch
				expected_install.join("source", ".coffle", "work", "backup", ".ex_dir"              ).mkdir
				expected_install.join("source", ".coffle", "work", "backup", ".ex_dir", "ex_file"   )  .touch
				expected_install.join("source", ".coffle", "work", "backup", ".link_dir"            ).mkdir
				expected_install.join("source", ".coffle", "work", "backup", ".link_dir", "ex_file" )  .touch
 
				# Target
				expected_install.join("target").mkpath
				expected_install.join("target", ".reg_file"                     ).make_symlink("../source/.coffle/work/output/_reg_file")
				expected_install.join("target", ".reg_dir"                      ).mkdir
				expected_install.join("target", ".reg_dir", "reg_file"          )  .make_symlink("../../source/.coffle/work/output/_reg_dir/reg_file")
				expected_install.join("target", ".ex_file"                      ).make_symlink("../source/.coffle/work/output/_ex_file")
				expected_install.join("target", ".ex_dir"                       ).mkdir
				expected_install.join("target", ".ex_dir", "ex_file"            )  .make_symlink("../../source/.coffle/work/output/_ex_dir/ex_file")
				expected_install.join("target", ".ex_dir", "other_file"         )  .touch
				expected_install.join("target", ".link_dir"                     ).make_symlink(".link_dir_target")
				expected_install.join("target", ".link_dir_target"              ).mkpath
				expected_install.join("target", ".link_dir_target", "ex_file"   )  .make_symlink("../../source/.coffle/work/output/_link_dir/ex_file")
				expected_install.join("target", ".link_dir_target", "other_file")  .touch


				##### Create the expected_uninstall directory

				# Start with the expected_install state
				FileUtils.cp_r expected_install.join("source").to_s, expected_uninstall.join("source").to_s

				# Source, output and org are not affected by uninstall.

				# The backup directory should be empty
				expected_uninstall.join("source", ".coffle", "work", "backup").rmtree
				expected_uninstall.join("source", ".coffle", "work", "backup").mkpath

				# The target should be the same as before installation
				FileUtils.cp_r actual.join("target").to_s, expected_uninstall.join("target").to_s



				##### Install and compare with expected_install

				coffle.build!
				coffle.install!(:overwrite=>true)

				assert_tree_equal(expected_install, actual)


				##### Uninstall and compare with expected_uninstall

				coffle.uninstall!

				assert_tree_equal(expected_uninstall, actual)




				#p expected_install.tree_entries
			end
		end
	end
end


