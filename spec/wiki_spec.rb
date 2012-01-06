require ::File.expand_path('../spec_helper.rb', __FILE__)

describe 'Wiki' do
  include Rack::Test::Methods
  include WikiHelpers

  let(:app) { SimpleWiki }
  subject { last_response.body }

  context "main page" do
    before { get '/' }

    it "have layout" do 
      should match %r/<!doctype html>/i
    end

    it "have right content" do
      should match %r/<p>This <em>is<\/em> Markdown<\/p>/i
    end
  end

  context "non-existing page" do
    before { get '/non-exists' }

    it "catch the exception" do
      should match %r/No such file/i
    end
  end

  context "sample page" do
    before { get '/sample' }
    it "have right content" do
      should match %r/<p>This is a page<\/p>/i
    end
  end

  context "table of contents" do
    before { get '/contents' }
    it "include all files" do
      read_dir(settings.views).each_with_object([]) do |f,arr|
        should match %r/<a href="\/#{f.chomp('.md')}">/i
      end
    end
  end

  context "editing pages" do
    before {
      @slug = '__spec'
      @file_name = File.join(settings.views,"#{@slug}.md")
      post @slug, :content => 'test. please ignore'
    }
    after {
      File.delete(@file_name) if File.exists?(@file_name)
    }

    it 'show edit form' do
      get "/edit/%s" % @slug
      should match %r/<form action="http:\/\/example.org\/#{@slug}" method="post"/i
    end

    it 'save the content' do
      File.new(@file_name).read.should match %r/test. please ignore/i
    end

    it 'redirect to the same page after save' do
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should == "http://example.org/%s" % @slug
      should match %r/test. please ignore/i
    end

    it 'delete page on empty content' do
      post @slug, :content => ''
      File.exists?(@file_name).should == false
    end
  end
end
