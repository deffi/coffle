#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/config'

def help
	puts <<help
Usage: #{$0} [--overwrite|-o] [--help|-h|-?] [--version]
  --overwrite : overwrite existing files (a backup will be created)
  --help      : print help message and exit
  --version   : print version and exit
help
end

opts={
	['--help', '-h', '-?'] => Proc.new { help; exit 1 },
	['--overwrite', '-o' ] => :overwrite,
	['--version'         ] => Proc.new { puts Config::VERSION; exit 1 }
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

backup_dir="backups/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}"


installer=Config::Installer.new('configs', ENV['HOME'], backup_dir)
installer.install options





