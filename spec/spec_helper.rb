require 'simplecov'
SimpleCov.start

require File.join(File.dirname(__FILE__),'..','page')
require File.join(File.dirname(__FILE__),'..','wiki')
require 'rack/test'
require 'rdiscount'

set :environment, :test
