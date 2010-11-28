require 'erb'

require 'coffle/template_methods'

module Coffle
	class Builder
		attr_reader :source, :target

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
			@source=source
			@target=target

			raise ArgumentError.new("source is not a Pathname") if !source.is_a? Pathname
			raise ArgumentError.new("target is not a Pathname") if !target.is_a? Pathname

			target.write process(source.read)
		end
	end
end

