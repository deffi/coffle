#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../lib/config'

source = "configs"
build  = "build"
target = ENV['HOME']
backup = "backups/#{Time.now.strftime("%Y-%m-%d_%H-%M-%S")}"

base=Config::Base.new(source, build, target, backup, :verbose=>true)
base.run

