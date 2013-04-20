#!/usr/bin/env ruby

require_relative '../lib/coffle'

repository = "."
target = ENV['HOME']

Coffle::Runner.new(repository, target, :verbose=>true).run

