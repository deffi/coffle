#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "."
target = ENV['HOME']

Coffle::Coffle.run(source, target, :verbose=>true)

