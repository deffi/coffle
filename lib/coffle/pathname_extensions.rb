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

	def newer?(other)
		self.mtime > other.mtime
	end

	def older?(other)
		self.mtime < other.mtime
	end

	def current?(other)
		not older?(other)
	end

	def touch
		open('a') {}
		t=Time.now
		utime t, t
	end

	def touch!
		make_container
		touch
	end

	def make_container
		dirname.mkpath
	end

	def set_time(time)
		self.utime time, time
	end

	def set_same_time(other)
		self.utime other.atime, other.mtime
	end

	def set_older(other, seconds=1)
		self.utime other.atime-seconds, other.mtime-seconds
	end

	def set_newer(other, seconds=1)
		self.utime other.atime+seconds, other.mtime+seconds
	end

	def present?         ; File.present?(         @path); end
	def proper_directory?; File.proper_directory?(@path); end
	def proper_file?     ; File.proper_file?(     @path); end
	def non_directory?   ; File.non_directory?(   @path); end
	def non_file?        ; File.non_file?(        @path); end

	def empty?
		raise Errno::ENOTDIR, to_s unless directory?

		entries=Dir.entries(self.to_s)
		entries==[".", ".."] or entries==["..", "."]
	end

	def ls(options="-lad")
		puts `ls #{options} --color=always #{@path}`
	end

	def to_pathname
		self
	end
end

