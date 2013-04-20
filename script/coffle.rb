#!/usr/bin/env ruby

require File.dirname(File.realpath(__FILE__)) + '/../lib/coffle'

source = "."
target = ENV['HOME']

Coffle::Runner.new(source, target, :verbose=>true).run

