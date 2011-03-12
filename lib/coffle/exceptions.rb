module Coffle
	module Exceptions
		class DirectoryIsNoCoffleSource < Exception; end
		class CoffleVersionTooOld < Exception; end

		class SourceConfigurationReadError < Exception; end
		class SourceConfigurationFileCorrupt < SourceConfigurationReadError; end
		class SourceConfigurationIsNotHash < SourceConfigurationReadError; end
		class SourceVersionMissing < SourceConfigurationReadError; end
		class SourceVersionIsNotInteger < SourceConfigurationReadError; end
	end
end

