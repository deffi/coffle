require 'fileutils'

class Pathname
	def absolute
		Pathname.getwd.join self
	end

	def write(string)
		raise "Cannot write into a non-file" if (exist? && !file?)

		open("w") { |file| file.write string }
	end

	def append(string)
		raise "Cannot write into a non-file" if (exist? && !file?)

		open("a") { |file| file.write string }
	end

	def file_identical?(other)
		self.file? and other.file? and self.read==other.read
	end

	def copy_file(other, preserve=false, dereference=true)
		FileUtils.copy_file self.to_s, other.to_s, preserve, dereference
	end
end

