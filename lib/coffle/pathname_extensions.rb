class Pathname
	def absolute
		Pathname.getwd.join self
	end

	def write(string)
		raise "Cannot write into a non-file" if (exist? && !file?)

		open("w") { |file| file.write string }
	end
end


