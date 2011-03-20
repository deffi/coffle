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
			MInstall      = "Installing     "
			MUninstall    = "Uninstalling   "
			MExist        = "Exists         "
			MBlocked      = "Blocked        "
			MCurrent      = "Current        "
			MOverwrite    = "Overwrite      "
			MBuilt        = "Built          "
			MSkipped      = "Skipped        "
			MModified     = "Modified       "
			MReplaced     = "Replaced       "
			MRestored     = "Restored       "
			MRemoved      = "Removed        "
			MNotInstalled = "Not installed  "
		end
	end
end

