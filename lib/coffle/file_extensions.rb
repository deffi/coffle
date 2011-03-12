class File
	# This is only different from exist? for symlinks that cannot be resolved
	# (including symlinks to symlinks to missing entries)
	def File.present?(path)
		File.exist?(path) || File.symlink?(path)
	end

	def File.proper_directory?(path)
		File.directory?(path) and not File.symlink?(path)
	end

	def File.proper_file?(path)
		File.file?(path) and not File.symlink?(path)
	end

	# Exists, but is not a directory (symlinks to directories are counted as
	# directories)
	def File.non_directory?(path)
		File.present?(path) and not File.directory?(path)
	end

	# Exists, but is not a file (symlinks to files are counted as files)
	def File.non_file?(path)
		File.present?(path) and not File.file?(path)
	end
end

