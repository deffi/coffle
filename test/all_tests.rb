#!/usr/bin/env ruby

Dir.glob("#{File.dirname(__FILE__)}/test_*.rb").each do |entry|
	require "#{entry}"
end

# at_axit, the AutoRunner will be invoked

