module Coffle
	#begin
	#	raise
	#rescue Exception=>e
	#	puts "================"
	#	puts e.backtrace
	#end

	unless @included_messages
		@included_messages=true

		module Messages
			MDir          = "Directory      "
			MCreate       = "Creating       "
			MExist        = "Exists         "
			MBlocked      = "Blocked        "
			MCurrent      = "Current        "
			MOverwrite    = "Overwrite      "
			MBuild        = "Building       "
			MModified     = "Modified       "
			MBackupExists = "Backup exists  "
			MNotInstalled = "Not installed  "
		end
	end
end

