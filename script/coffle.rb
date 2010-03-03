#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "configs"
target = ENV['HOME']

coffle=Coffle::Coffle.new(source, target, :verbose=>true)
coffle.run

