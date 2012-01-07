# encoding: utf-8

require 'sinatra'
require 'rdiscount'

module WikiHelpers
  #sorts files by modification date and filters wiki templates and ./..
  def read_dir(dir)
    Dir.entries(dir).map {|i| i unless $excl.include?(i) or i.match(%r/^\./i)}.compact.sort_by {|c| File.stat(File.join(settings.views, c)).mtime}.reverse
  end

  def page_exists?(page)
    File.exists?(File.join(settings.views,"#{page}.md")) and not $excl.include?(page)
  end
end

class SimpleWiki < Sinatra::Base
  configure do
    $excl = ['.', '..', 'layout.erb', 'edit.erb', 'new.erb']
    set :markdown, :layout_engine => :erb
    set :views, File.join(File.dirname(__FILE__),'content')
  end

  helpers do
    include WikiHelpers
  end

  get '/' do
    markdown :homepage
  end

  get '/contents' do
    contents = read_dir(settings.views).each_with_object([]) do |f,arr|
      slug = f.chomp('.md')
      arr << '<li><a href="/' + slug + '">' + slug + '</a></li>'
    end.join
    erb '<h1>Table of Contents</h1><ul>' + contents + '</ul>'
  end

  get '/new' do
    erb :new
  end

  get '/new/:page' do |page|
    redirect "/#{page}" if page_exists?(page)
    @newname = page
    erb :new
  end

  post '/save' do
    redirect '/' if params[:slug].empty? or params[:content].empty?
    page = params[:slug].gsub(" ", "_").downcase
    fname = File.join(settings.views,"#{page}.md")
    File.open(fname,"w+") { |f| f.write(params[:content]) }
    redirect page.to_sym
  end

  get '/edit/:page' do |page|
    @slug = page
    @content = File.new(File.join(settings.views,"#{@slug}.md")).read
    erb :edit
  end

  get '/:page' do |page|
    redirect "/new/#{page}" unless page_exists?(page)
    @slug, @edit = page, true
    markdown page.to_sym
  end

  post '/:page' do |page|
    fname = File.join(settings.views,"#{page}.md")
    if params[:content].empty?
      File.delete(fname)
      redirect '/'
    else
      File.open(fname,"w+") { |f| f.write(params[:content]) }
      redirect page.to_sym
    end
  end
end
