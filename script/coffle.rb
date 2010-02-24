#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/coffle'

source = "configs"
build  = "build"
target = ENV['HOME']
backup = "backups/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}"

coffle=Coffle::Coffle.new(source, build, target, backup, :verbose=>true)
coffle.run

