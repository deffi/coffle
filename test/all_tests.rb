#!/usr/bin/env ruby

Dir.glob("#{File.dirname(__FILE__)}/*_test.rb").each do |entry|
	require "#{entry}"
end

# at_axit, the AutoRunner will be invoked

