# encoding: utf-8

require 'sinatra'
require 'oauth'
require 'twitter'
require 'yaml'
require File.join(File.dirname(__FILE__),'page')
require File.join(File.dirname(__FILE__),'helpers')

ENV['RACK_ENV'] ||= "development"

class SimpleWiki < Sinatra::Base
  configure do
    enable :sessions
    enable :logging
    set :environment, ENV['RACK_ENV']
    set :markdown, :layout_engine => :erb
    # ready to deploy on heroku
    begin
      config = YAML.load_file(File.join(File.dirname(__FILE__),'config.yml'))
    rescue
      config = Hash.new
    end  
    TW_KEY = ENV['TW_KEY'] || config['tw_key']
    TW_SECRET = ENV['TW_SECRET'] || config['tw_secret']
    BASE_URL = ENV['BASE_URL'] || config['base_url']
    users = ENV['USERS'] || config['users']
    USERS = users.kind_of?(String) ? users.split(',').map(&:strip) : users
  end

  helpers do
    include WikiHelpers
    alias_method :h, :escape_html
  end

  before do
    session[:oauth] ||= {}   # we'll store the request and access tokens here
    begin
      @request_token = get_request_token
      @access_token = get_access_token unless @access_token
      @client = setup_client(@access_token)
    rescue Exception => @ex
      logger.error @ex.to_s
    end
  end

  get '/' do
    @page, @edit = Page.new('homepage'), true
    erb '<%= @page.to_html %>'
  end

  get '/contents' do
    authorize!
    contents = Page.list.each_with_object([]) do |p,arr|
      arr << "<li>#{link_to(p)}</li>"
    end.join
    erb '<h1>Table of Contents</h1><ul>' + contents + '</ul>'
  end

  get '/search' do
    authorize!
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
    begin
      redirect @request_token.authorize_url
    rescue Exception => @ex
      return erb %{ <div class="alert-message error">problem: <%=h @ex.to_s %></div> }
    end
  end

  get '/logout' do
    session[:oauth] = nil
    @request_token = nil
    @access_token = nil
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
    authorize!
    @page = Page.new('New page')
    erb :new
  end

  get '/new/:page' do |page|
    authorize!
    @page = Page.new(page)
    if @page.exists?
      redirect @page.title.to_sym
    else
      erb :new
    end
  end

  post '/save' do
    authorize!
    redirect '/' if params[:slug].empty? or params[:content].empty?
    @page = Page.new(params[:slug])
    @page.save!(params[:content])
    redirect @page.title.to_sym
  end

  get '/edit/:page' do |page|
    authorize!
    @page = Page.new(page)
    erb :edit
  end

  get '/:page' do |page|
    authorize!
    @page, @edit = Page.new(page), true
    redirect "/new/#{page}" unless @page.exists?
    erb '<%= @page.to_html %>'
  end

  post '/:page' do |page|
    authorize!
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
