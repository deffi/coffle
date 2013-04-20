#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

repository = "testdata/source"
target     = "testdata/target"

Coffle::Runner.new(repository, target, :verbose=>true).run

