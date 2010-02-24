$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Coffle
  VERSION = '0.1.0'
end

#require "#{File.dirname(__FILE__)}/tasker/worker/worker.rb"
Dir["#{File.dirname(__FILE__)}/coffle/**/*.rb"].sort.each { |lib| require lib }

