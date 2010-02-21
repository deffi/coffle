require 'pathname'

module Config
	module Filenames
		def unescape_filename(filename)
			if filename =~ /^-/
				filename[1..-1]
			elsif filename =~ /^_/
				".#{filename[1..-1]}"
			else
				filename
			end
		end

		def unescape_path(path)
			case path
			when String
				path.split('/').map { |part|
					unescape_filename part
				}.join('/')
			when Pathname
				Pathname.new(unescape_path(path.to_s))
			else raise "Unhandled type"
			end
		end
	end
end

