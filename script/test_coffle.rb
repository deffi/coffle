#!/usr/bin/env ruby

require_relative '../lib/coffle'

repository = "testdata/source"
target     = "testdata/target"

Coffle::Runner.new(repository, target, :verbose=>true).run

