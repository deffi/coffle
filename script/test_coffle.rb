#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "testdata/source"
build  = "testdata/build"
backup = "testdata/backups/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}"
target = "testdata/target"

coffle=Coffle::Coffle.new(source, build, target, backup, :verbose=>true)
coffle.run

