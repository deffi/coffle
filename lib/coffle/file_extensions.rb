class File
	# TODO test for this

	def File.present?(path)
		File.exist?(path) || File.symlink?(path)
	end

	def File.proper_file?(path)
		File.file?(path) and not File.symlink?(path)
	end

	def File.proper_directory?(path)
		File.directory?(path) and not File.symlink?(path)
	end
end

