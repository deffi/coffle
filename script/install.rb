#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/config'

def help
	puts <<help
Usage: #{$0} [--overwrite|-o] [--help|-h|-?]
help
end

opts={
	['--help', '-h', '-?'] => Proc.new { help; exit 1 },
	['--overwrite', '-o' ] => :overwrite
}

options={}
while arg=ARGV.shift
	opts.each_pair do |values, action|
		if values.include? arg
			case action
			when Symbol: options[action]=true
			when Proc: action.call
			else raise "Unknown action for #{values[0]}"
			end
		end
	end
end


installer=Config::Installer.new('configs', ENV['HOME'])
installer.install options





