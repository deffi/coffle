#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/config'

source = "testdata/source"
build  = "testdata/build"
backup = "testdata/backups/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}"
target = "testdata/target"

base=Config::Base.new(source, build, target, backup, :verbose=>true)
base.run

