require File.dirname(__FILE__) + '/test_helper.rb'

module Coffle
	class FullTest <Test::Unit::TestCase
		include TestHelper

		def test_full
			with_testdir do |dir|
				# repository                                    in actual/repository
				# target                                        in actual/target
				# expected directories for after installation   in expected_install/
				# expected directories for after uninstallation in expected_uninstall/
				actual            =dir.join("actual"            ).absolute; actual            .mkpath
				expected_install  =dir.join("expected_install"  ).absolute; expected_install  .mkpath
				expected_uninstall=dir.join("expected_uninstall").absolute; expected_uninstall.mkpath


				##### Create the coffle (also creates the output and target directories)
				actual.join("repository", ".coffle").mkpath
				Coffle.initialize_repository!(dir.join("actual", "repository"))
				coffle=Coffle.new(dir.join("actual", "repository"), dir.join("actual", "target"))


				##### Create the actual directory

				# Repository
				actual.join("repository").mkpath                         # repository
				actual.join("repository", "_reg_file").touch             # |-.reg_file   - Regular file
				actual.join("repository", "_reg_dir").mkdir              # |-.reg_dir    - Regular directory
				actual.join("repository", "_reg_dir", "reg_file").touch  # | '-reg_file  - Regular file in directory
				actual.join("repository", "_ex_file").touch              # |-.ex_file    - Existing file
				actual.join("repository", "_ex_dir").mkdir               # |-.ex_dir     - Existing directory
				actual.join("repository", "_ex_dir", "ex_file").touch    # | '-ex_file   - Existing file in directory
				actual.join("repository", "_link_dir").mkdir             # '-.link_dir   - Existing symlinked directory
				actual.join("repository", "_link_dir", "ex_file").touch  #   '-ex_file   - Existing file in symlinked directory


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

				# Repository - same as actual
				FileUtils.cp_r actual.join("repository").to_s, expected_install.join("repository").to_s

				# Output
				expected_install.join("repository", ".coffle", "work", "output").mkpath
				expected_install.join("repository", ".coffle", "work", "output", ".reg_file"            ).touch
				expected_install.join("repository", ".coffle", "work", "output", ".reg_dir"             ).mkdir
				expected_install.join("repository", ".coffle", "work", "output", ".reg_dir", "reg_file" )  .touch
				expected_install.join("repository", ".coffle", "work", "output", ".ex_file"             ).touch
				expected_install.join("repository", ".coffle", "work", "output", ".ex_dir"              ).mkdir
				expected_install.join("repository", ".coffle", "work", "output", ".ex_dir", "ex_file"   )  .touch
				expected_install.join("repository", ".coffle", "work", "output", ".link_dir"            ).mkdir
				expected_install.join("repository", ".coffle", "work", "output", ".link_dir", "ex_file" )  .touch

				# Org
				expected_install.join("repository", ".coffle", "work", "org").mkpath
				expected_install.join("repository", ".coffle", "work", "org", ".reg_file"            ).touch
				expected_install.join("repository", ".coffle", "work", "org", ".reg_dir"             ).mkdir
				expected_install.join("repository", ".coffle", "work", "org", ".reg_dir", "reg_file" )  .touch
				expected_install.join("repository", ".coffle", "work", "org", ".ex_file"             ).touch
				expected_install.join("repository", ".coffle", "work", "org", ".ex_dir"              ).mkdir
				expected_install.join("repository", ".coffle", "work", "org", ".ex_dir", "ex_file"   )  .touch
				expected_install.join("repository", ".coffle", "work", "org", ".link_dir"            ).mkdir
				expected_install.join("repository", ".coffle", "work", "org", ".link_dir", "ex_file" )  .touch

				# Backup
				expected_install.join("repository", ".coffle", "work", "backup").mkpath
				expected_install.join("repository", ".coffle", "work", "backup", ".ex_file"             ).touch
				expected_install.join("repository", ".coffle", "work", "backup", ".ex_dir"              ).mkdir
				expected_install.join("repository", ".coffle", "work", "backup", ".ex_dir", "ex_file"   )  .touch
				expected_install.join("repository", ".coffle", "work", "backup", ".link_dir"            ).mkdir
				expected_install.join("repository", ".coffle", "work", "backup", ".link_dir", "ex_file" )  .touch
 
				# Target
				expected_install.join("target").mkpath
				expected_install.join("target", ".reg_file"                     ).make_symlink("../repository/.coffle/work/output/.reg_file")
				expected_install.join("target", ".reg_dir"                      ).mkdir
				expected_install.join("target", ".reg_dir", "reg_file"          )  .make_symlink("../../repository/.coffle/work/output/.reg_dir/reg_file")
				expected_install.join("target", ".ex_file"                      ).make_symlink("../repository/.coffle/work/output/.ex_file")
				expected_install.join("target", ".ex_dir"                       ).mkdir
				expected_install.join("target", ".ex_dir", "ex_file"            )  .make_symlink("../../repository/.coffle/work/output/.ex_dir/ex_file")
				expected_install.join("target", ".ex_dir", "other_file"         )  .touch
				expected_install.join("target", ".link_dir"                     ).make_symlink(".link_dir_target")
				expected_install.join("target", ".link_dir_target"              ).mkpath
				expected_install.join("target", ".link_dir_target", "ex_file"   )  .make_symlink("../../repository/.coffle/work/output/.link_dir/ex_file")
				expected_install.join("target", ".link_dir_target", "other_file")  .touch


				##### Create the expected_uninstall directory

				# Start with the expected_install state
				FileUtils.cp_r expected_install.join("repository").to_s, expected_uninstall.join("repository").to_s

				# Repository, output and org are not affected by uninstall.

				# The backup directory should be empty
				expected_uninstall.join("repository", ".coffle", "work", "backup").rmtree
				expected_uninstall.join("repository", ".coffle", "work", "backup").mkpath

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


