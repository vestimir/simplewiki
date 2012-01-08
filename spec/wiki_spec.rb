require ::File.expand_path('../spec_helper.rb', __FILE__)

describe 'Wiki' do
  include Rack::Test::Methods
  include WikiHelpers

  let(:app) { SimpleWiki }
  subject { last_response.body }

  context 'main page' do
    before { get '/' }

    it 'have layout' do
      should match %r/<!doctype html>/i
    end

    it 'should exists' do
      File.exists?(File.join(settings.views, 'homepage.md')).should == true
    end
  end

  context 'non-existing page' do
    before { get '/non-exists' }

    it 'redirect to new page form' do
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should == "http://example.org/new/non-exists"
    end
  end

  context 'table of contents' do
    before { get '/contents' }
    it 'include all files' do
      read_dir(settings.views).each_with_object([]) do |f,arr|
        should match %r/<a href="\/#{f.chomp('.md')}">/i
      end
    end
  end

  context 'new page' do
    before {
      @slug = '__spec_new_page'
      @file_name = File.join(settings.views,"#{@slug}.md")
    }
    after {
      File.delete(@file_name) if File.exists?(@file_name)
    }

    it 'show new page form' do
      get '/new'
      should match %r/<form action="http:\/\/example.org\/save" method="post"/i
    end

    it 'save content' do
      post '/save', :slug => '  Spec New Page', :content => 'test. please ignore'
      File.new(@file_name).read.should match %r/test. please ignore/i
    end
  end

  context 'editing pages' do
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

    it 'should not delete homepage' do
      post 'homepage', :content => ''
      File.exists?(File.join(settings.views, 'homepage.md')).should == true
    end
  end

  context 'searching pages' do
    before {
      @slug = 'search_me'
      @file_name = File.join(settings.views, "#{@slug}.md")
      File.open(@file_name, 'w+') { |f| f.write('abrakadabra') }
    }
    after {
      File.delete(@file_name) if File.exists?(@file_name)
    }

    it 'should load a page on exact match' do
      get '/search?q=search+me'
      follow_redirect!
      last_request.url.should == 'http://example.org/%s' % @slug
    end

    it 'should redirect to homepage on empty string' do
      get '/search?q='
      follow_redirect!
      last_request.url.should == "http://example.org/"
    end

    it 'should redirect to homepage if search query is less than 3 chars' do
      get '/search?q=as'
      follow_redirect!
      last_request.url.should == "http://example.org/"
    end

    it 'should display results page' do
      get '/search?q=abrakadabra'
      should match %r/#{@slug}<\/a>/i
    end
  end
end
