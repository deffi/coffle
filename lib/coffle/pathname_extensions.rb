class Pathname
	def absolute
		Pathname.getwd.join self
	end
end


