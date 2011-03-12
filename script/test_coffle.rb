#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "testdata/source"
target = "testdata/target"

Coffle::Runner.new(source, target, :verbose=>true).run

