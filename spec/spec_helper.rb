require 'simplecov'
SimpleCov.start

require File.join(File.dirname(__FILE__),'..','wiki')
require 'rack/test'
require 'rdiscount'

set :environment, :test
set :views, File.join(File.dirname(__FILE__),'..','content')
