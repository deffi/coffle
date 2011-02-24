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

	def set_same_time(other)
		self.utime other.atime, other.mtime
	end

	def set_older(other, seconds=1)
		self.utime other.atime-seconds, other.mtime-seconds
	end

	def set_newer(other, seconds=1)
		self.utime other.atime+seconds, other.mtime+seconds
	end

	# This is only different from exist? for symlinks that cannot be resolved
	# (including symlinks to symlinks to missing entries)
	def present?
		exist? or symlink?
	end

	def proper_directory?
		directory? and not symlink?
	end

	def proper_file?
		file? and not symlink?
	end
end

