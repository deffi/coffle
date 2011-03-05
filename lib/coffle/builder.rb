require 'erb'

require 'coffle/template_methods'

module Coffle
	class Builder
		# Include modules that should be available to the templates in
		# TemplateMethods
		include TemplateMethods

		def initialize(entry)
			@entry=entry

			@skipped=false
		end

		def process(input)
			template=ERB.new(input, nil, "-")
			result=template.result(binding)
			result unless skipped?
		end
	end
end

