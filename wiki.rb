# encoding: utf-8

require 'sinatra'
require 'sinatra/config_file'
require File.join(File.dirname(__FILE__),'page')

module WikiHelpers
  def link_to(page)
    '<a href="/' + page + '">' + page + '</a>'
  end
end

class SimpleWiki < Sinatra::Base
  configure do
    config_file File.join(File.dirname(__FILE__),'config.yml') 
    set :markdown, :layout_engine => :erb
  end

  helpers do
    include WikiHelpers
  end

  get '/' do
    @page, @edit = Page.new('homepage'), true
    erb '<%= @page.to_html %>'
  end

  get '/contents' do
    contents = Page.list.each_with_object([]) do |p,arr|
      arr << "<li>#{link_to(p)}</li>"
    end.join
    erb '<h1>Table of Contents</h1><ul>' + contents + '</ul>'
  end

  get '/search' do
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

  get '/new' do
    @page = Page.new('New page')
    erb :new
  end

  get '/new/:page' do |page|
    @page = Page.new(page)
    if @page.exists?
      redirect @page.title.to_sym
    else
      erb :new
    end
  end

  post '/save' do
    redirect '/' if params[:slug].empty? or params[:content].empty?
    @page = Page.new(params[:slug])
    @page.save!(params[:content])
    redirect @page.title.to_sym
  end

  get '/edit/:page' do |page|
    @page = Page.new(page)
    erb :edit
  end

  get '/:page' do |page|
    @page, @edit = Page.new(page), true
    redirect "/new/#{page}" unless @page.exists?
    erb '<%= @page.to_html %>'
  end

  post '/:page' do |page|
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
