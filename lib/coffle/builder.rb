require 'erb'

require 'coffle/template_methods'

module Coffle
	class Builder
		# Include modules that should be available to the templates in
		# TemplateMethods
		include TemplateMethods

		def Builder.build(source, target)
			#FileUtils.copy_file source, target, preserve=false, dereference=true
			Builder.new.build source,target
		end

		def initialize
		end

		def process(text)
			template=ERB.new(text, nil, "-")
			template.result(binding)
		end

		def build(source, target)
			#FileUtils.copy_file @source, @target, preserve=false, dereference=true

			@source=source
			@target=target

			File.open(@target, "w") do |file|
				file.print process(File.read(@source))
			end
		end
	end
end

