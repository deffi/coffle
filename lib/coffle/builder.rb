require 'erb'
require 'socket'

module Coffle
	module TemplateMethods
		def automessage(comment="# ", width=80)
			time=Time.now.strftime("%Y-%m-%d %H:%M:%S %z")

			# Note the extra indentation before the command, somehow the word
			# wrapping seems to mess up the indenting.
			message=<<-end
This file was autogenerated from #{@source} by #{username}@#{hostname} on #{time}. You should not make any changes here, as they might be overwritten when the file is regenerated.

To regenerate this file, execute the following command:
      #{$0} build
in the following directory:
	#{Dir.getwd}
end
			message.wrap(width-comment.length).prefix_lines(comment)
		end

		def username
			ENV['USERNAME']
		end

		def hostname
			Socket.gethostname
		end

		def host(*hosts)
			yield if hosts.include? hostname
		end
	end
end

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

