require_relative '../wiki.rb'
require 'rack/test'

set :environment, :test

def app
  Sinatra::Application
end

test_file = CONTENT + 'test.md'

describe 'Wiki' do
  include Rack::Test::Methods

  before(:all) do
    File.new(test_file, 'w')
    File.open(test_file, 'w') { |f| f.write("This is a page\n") }
  end

  after(:all) do
    # File.delete(test_file)
  end

  it "should have a layout" do
    get '/'
    last_response.body.downcase.should match %r/<!doctype html>/i
  end

  it "should have homepage" do
    get '/'
    last_response.body.should match %r/<p>This <em>is<\/em> Markdown<\/p>/i
  end

  it "should have slug page" do
    get '/test'
    last_response.body.should match %r/<p>This is a page<\/p>/i
  end

  it "should have table of contents" do
    get '/contents'
    read_dir(CONTENT).each do |f|
      f.gsub! '.md', ''
      last_response.body.should match %r/<a href="\/#{f}">/i
    end
  end

  it "should have an edit link" do
    get '/test'
    last_response.body.should match %r/Edit page/i
  end

  it "should read a file" do
    read_file(test_file).should == "This is a page\n"
  end

  it "should write a file" do
    write_file(test_file, "Test\n")
    read_file(test_file).should == "Test\n"
  end

  it "should edit a page" do
    post '/test/edit', params= { :content => 'Test2' }
    follow_redirect!
    last_response.body.should match %r/Test2/i
  end
end
