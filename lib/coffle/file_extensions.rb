class File
	def File.present?(path)
		File.exist?(path) || File.symlink?(path)
	end
end

