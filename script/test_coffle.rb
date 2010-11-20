#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "testdata/source"
target = "testdata/target"

puts "source: #{source}, target: #{target}"


coffle=Coffle::Coffle.new(source, target, :verbose=>true)
coffle.run

