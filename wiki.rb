# encoding: utf-8

require 'sinatra'
require 'oauth'
require 'twitter'
require 'yaml'
require File.join(File.dirname(__FILE__),'page')

module WikiHelpers
  def link_to(page)
    '<a href="/' + page + '">' + page + '</a>'
  end

  def signed_in?
    !session[:oauth][:access_token].nil?
  end
end


class SimpleWiki < Sinatra::Base
  configure do
    enable :sessions
    enable :logging
    set :environment, ENV['RACK_ENV']
    set :markdown, :layout_engine => :erb
    $c = YAML.load_file(File.join(File.dirname(__FILE__),'config.yml'))
  end

  helpers do
    include WikiHelpers
    alias_method :h, :escape_html
  end

  before do
    session[:oauth] ||= {}   # we'll store the request and access tokens here
    @consumer = OAuth::Consumer.new($c['tw_key'], $c['tw_secret'], :site => "http://twitter.com")
    # generate a request token for this user session if we haven't already
    request_token = session[:oauth][:request_token]   
    request_token_secret = session[:oauth][:request_token_secret]
    if request_token.nil? or request_token_secret.nil?
      @request_token = @consumer.get_request_token(:oauth_callback => "#{$c['host']}/auth")
      session[:oauth][:request_token] = @request_token.token
      session[:oauth][:request_token_secret] = @request_token.secret
    else
      # we made this user's request token before, so recreate the object
      @request_token = OAuth::RequestToken.new(@consumer, request_token, request_token_secret)  
    end  
    access_token = session[:oauth][:access_token]
    access_token_secret = session[:oauth][:access_token_secret]
    unless access_token.nil? or access_token_secret.nil?
      # the ultimate goal is to get here
      @access_token = OAuth::AccessToken.new(@consumer, access_token, access_token_secret)
      oauth = Twitter::OAuth.new($c['tw_key'], $c['tw_secret'])
      oauth.authorize_from_access(@access_token.token, @access_token.secret)     
      @client = Twitter::Base.new(oauth)
    end
  end

  get '/' do
    @page, @edit = Page.new('homepage'), true
    erb '<%= @page.to_html %>'
  end

  get '/contents' do
    redirect '/' unless @access_token
    contents = Page.list.each_with_object([]) do |p,arr|
      arr << "<li>#{link_to(p)}</li>"
    end.join
    erb '<h1>Table of Contents</h1><ul>' + contents + '</ul>'
  end

  get '/search' do
    redirect '/' unless @access_token
    #redirect to index if query string is empty
    redirect to('/') if params[:q].empty? or params[:q].length < 3

    #redirect to the page if there's an exact match in the title
    page = params[:q].gsub(" ", "_").downcase
    redirect to("/#{page}") if Page.new(page).exists?

    #finally search through files
    results = Page.list.each_with_object([]) do |p,arr|
      page = Page.new(p)
      arr << "<li>#{link_to(p)}</li>" if page.raw.match %r/#{params[:q]}/i
    end.join
    erb "<h1>Search results for &quot;#{params[:q]}&quot;</h1><ul>" + results + '</ul>'
  end

  # OAuth
  get '/login' do
    redirect @request_token.authorize_url
  end

  get '/logout' do
    session[:oauth] = nil
    redirect '/'
  end

  get "/auth" do
    @access_token = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    session[:oauth][:access_token] = @access_token.token
    session[:oauth][:access_token_secret] = @access_token.secret
    redirect "/contents"
  end

  # Working with Pages

  get '/new' do
    redirect '/' unless @access_token
    @page = Page.new('New page')
    erb :new
  end

  get '/new/:page' do |page|
    redirect '/' unless @access_token
    @page = Page.new(page)
    if @page.exists?
      redirect @page.title.to_sym
    else
      erb :new
    end
  end

  post '/save' do
    redirect '/' if params[:slug].empty? or params[:content].empty? or not @access_token
    @page = Page.new(params[:slug])
    @page.save!(params[:content])
    redirect @page.title.to_sym
  end

  get '/edit/:page' do |page|
    redirect '/' unless @access_token
    @page = Page.new(page)
    erb :edit
  end

  get '/:page' do |page|
    redirect '/' unless @access_token
    @page, @edit = Page.new(page), true
    redirect "/new/#{page}" unless @page.exists?
    erb '<%= @page.to_html %>'
  end

  post '/:page' do |page|
    redirect '/' unless @access_token
    @page = Page.new(page)
    if params[:content].empty? and page != 'homepage'
      @page.destroy!
      redirect '/'
    else
      @page.save!(params[:content])
      redirect @page.title.to_sym
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
