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
      Page.new('homepage').exists?($excl).should == true
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
      Page.list($excl).each_with_object([]) do |p,arr|
        should match %r/#{link_to(p)}/i
      end
    end
  end

  context 'new page' do
    before {
      @page = Page.new('  Spec New Page')
    }
    after {
      @page.destroy!
    }

    it 'show new page form' do
      get '/new'
      should match %r/<form action="http:\/\/example.org\/save" method="post"/i
    end

    it 'save the content' do
      post '/save', :slug => @page.name, :content => 'test. please ignore'
      @page.raw.should match %r/test. please ignore/i
    end

    it 'redirect to the page, if exists' do
      @page.save!('test. please ignore')
      get "/new/#{@page.title}"
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should == "http://example.org/%s" % @page.title
    end

  end

  context 'editing pages' do
    before {
      @page = Page.new('__spec')
      post @page.title, :content => 'test. please ignore'
    }
    after {
      @page.destroy!
    }

    it 'show edit form' do
      get "/edit/%s" % @page.title
      should match %r/<form action="http:\/\/example.org\/#{@page.title}" method="post"/i
    end

    it 'save the content' do
      @page.raw.should match %r/test. please ignore/i
    end

    it 'redirect to the same page after save' do
      last_response.should be_redirect
      follow_redirect!
      last_request.url.should == "http://example.org/%s" % @page.title
      should match %r/test. please ignore/i
    end

    it 'delete page on empty content' do
      post @page.title, :content => ''
      @page.exists?($excl).should == false
    end

    it 'should not delete homepage' do
      post 'homepage', :content => ''
      Page.new('homepage').exists?($excl).should == true
    end
  end

  context 'searching pages' do
    before {
      @page = Page.new('search_me')
      @page.save!('abrakadabra')
    }
    after {
      @page.destroy!
    }

    it 'should load a page on exact match' do
      get '/search?q=search+me'
      follow_redirect!
      last_request.url.should == 'http://example.org/%s' % @page.title
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
      should match %r/#{@page.title}<\/a>/i
    end
  end
end
