require_relative '../wiki.rb'
require 'rack/test'

set :environment, :test

def app
    Sinatra::Application
end

describe 'Wiki' do
    include Rack::Test::Methods

    it "should have a layout" do
        get '/'
        last_response.body.downcase.should match %r/<!doctype html>/i
    end

    it "should have homepage" do
        get '/'
        last_response.body.should match %r/<p>This <em>is<\/em> Markdown<\/p>/i
    end

    it "should have slug page" do
        get '/sample'
        last_response.body.should match %r/<p>This is a page<\/p>/i
    end

    it "should have table of contents" do
        get '/contents'
        read_dir(CONTENT).each do |f|
            f.gsub! '.md', ''
            last_response.body.should match %r/<a href="\/#{f}">/i
        end
    end
end
