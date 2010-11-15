#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "."
target = ENV['HOME']

coffle=Coffle::Coffle.new(source, target, :verbose=>true)
coffle.run

