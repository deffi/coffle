#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "testdata/source"
target = "testdata/target"

Coffle::Coffle.run(source, target, :verbose=>true)

