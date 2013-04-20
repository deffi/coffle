#!/usr/bin/env ruby

$: << File.dirname(__FILE__)

Dir.glob("#{File.dirname(__FILE__)}/*_test.rb").each do |entry|
	require "#{File.basename(entry)}"
end

# at_axit, the AutoRunner will be invoked

