module Coffle
	module TemplateMethods
		module Ssh
			# Protocol 2 public key: [options] keytype key comment
			# keytype is ssh-dss or ssh-rsa
			class Key
				attr_reader :complete
				attr_reader :options, :type, :key, :comment
				attr_reader :name

				def initialize(line)
					@complete=line

					# May fail in academic cases with an invalid key type and
					# the string "ssh-dss" or "ssh-rsa" in the key or comment.
					if line=~/^((.*)\s+)?(ssh-dss|ssh-rsa)\s+([^\s]+)\s+(.*)$/
						@options=$2
						@type=$3
						@key=$4
						@comment=$5
					else
						raise ArgumentError, "invalid key #{line.inspect}"
					end

					# Better, but does not support quoted spaces, quotes or
					# backslashes in command
					#if line=~/^(ssh-dss|ssh_rsa)\s+([^\s]+)\s+(.*)$/
					#	@options=""
					#	@type=$1
					#	@key=$2
					#	@comment=$3
					#elsif line=~/^([^\s]+)\s+(ssh-dss|ssh_rsa)\s+([^\s]+)\s+(.*)$/
					#	@options=$1
					#	@type=$2
					#	@key=$3
					#	@comment=$4
					#else
					#	raise ArgumentError, "invalid key"
					#end

					@name=@comment.split(" ")[0]
				end
			end

			def _parse_keys(lines)
				keys={}

				lines.map { |line|
					line.chomp
				}.reject { |line|
					line.empty?
				}.each { |line|
					key=Key.new(line)
					keys[key.name]=key
				}

				keys
			end

			def define_keys
				@keys=_parse_keys(capture{yield})
			end

			def key(*names)
				names.map { |name|
					@keys[name].complete
				}.join("\n")
			end
		end
	end
end

