class String
	def wrap(width)
		# Improved regexp: may also break after a slash (not replacing it)
		gsub(/(.{1,#{width}})( +|$\n?|(\/))|(.{1,#{width}})/, "\\1\\3\\4\n") 
	end

	def prefix_lines(prefix)
		split("\n").map { |line| prefix+line }.join("\n")
	end
end

