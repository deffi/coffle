module Coffle
	module Exceptions
		class DirectoryIsNoRepository < Exception; end
		class CoffleVersionTooOld < Exception; end

		class RepositoryConfigurationReadError < Exception; end
		class RepositoryConfigurationFileCorrupt < RepositoryConfigurationReadError; end
		class RepositoryConfigurationIsNotHash < RepositoryConfigurationReadError; end
		class RepositoryVersionMissing < RepositoryConfigurationReadError; end
		class RepositoryVersionIsNotInteger < RepositoryConfigurationReadError; end
	end
end

