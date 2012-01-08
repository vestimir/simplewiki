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

  def link_to(page)
    '<a href="/' + page + '">' + page + '</a>'
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
    @edit = true
    @slug = 'homepage'
    markdown @slug.to_sym
  end

  get '/contents' do
    contents = read_dir(settings.views).each_with_object([]) do |f,arr|
      arr << "<li>#{link_to(f.chomp('.md'))}</li>"
    end.join
    erb '<h1>Table of Contents</h1><ul>' + contents + '</ul>'
  end

  get '/search' do
    #redirect to index if query string is empty
    redirect to('/') if params[:q].empty? or params[:q].length < 3

    #redirect to the page if there's an exact match in the title
    page = params[:q].gsub(" ", "_").downcase
    redirect to("/#{page}") if page_exists?(page)

    #finally search through files
    results = read_dir(settings.views).each_with_object([]) do |f,arr|
      content = File.new(File.join(settings.views, f)).read
      arr << "<li>#{link_to(f.chomp('.md'))}</li>" if content.match %r/#{params[:q]}/i
    end.join
    erb "<h1>Search results for &quot;#{params[:q]}&quot;</h1><ul>" + results + '</ul>'
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
    if params[:content].empty? and page != 'homepage'
      File.delete(fname)
      redirect '/'
    else
      File.open(fname,"w+") { |f| f.write(params[:content]) }
      redirect page.to_sym
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
