require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] ||= "test"

require File.join(File.dirname(__FILE__),'..','page')
require File.join(File.dirname(__FILE__),'..','wiki')
require 'rack/test'
require 'rdiscount'

set :environment, ENV['RACK_ENV']
