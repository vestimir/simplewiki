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
end
