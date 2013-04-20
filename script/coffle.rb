#!/usr/bin/env ruby

require File.dirname(File.realpath(__FILE__)) + '/../lib/coffle'

repository = "."
target = ENV['HOME']

Coffle::Runner.new(repository, target, :verbose=>true).run

