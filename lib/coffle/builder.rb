module Coffle
	class Builder
		def Builder.build(source, target)
			FileUtils.copy_file source, target, preserve=false, dereference=true
		end
	end
end

