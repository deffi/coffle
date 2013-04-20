#!/usr/bin/env ruby

Dir.glob("#{File.dirname(__FILE__)}/*_test.rb").each do |entry|
	require_relative "#{File.basename(entry)}"
end

# at_axit, the AutoRunner will be invoked

