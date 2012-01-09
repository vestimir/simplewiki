# encoding: utf-8

require 'sinatra'
require 'rdiscount'

class Page
  attr_reader :name

  EXCLUDES = ['.', '..', 'layout.erb', 'edit.erb', 'new.erb']

  def Page.dir
    File.join(File.dirname(__FILE__),'content')
  end

  def Page.list
    Dir.entries(Page.dir).map { |i|
      i.chomp('.md') unless EXCLUDES.include?(i) or i.match(%r/^\./i)
    }.compact.sort_by {|c| 
        File.stat(File.join(Page.dir, "#{c}.md")).mtime
      }.reverse
  end

  def initialize(name)
    @name = name
    @fname = File.join(Page.dir,"#{self.title}.md")
    @excl = ['.', '..', 'layout.erb', 'edit.erb', 'new.erb']
  end

  def title
    name.gsub(" ", "_").downcase
  end

  def exists?
    File.exists?(@fname) and not EXCLUDES.include?(self.title)
  end

  def raw
    File.new(@fname).read
  end

  def to_link
    '<a href="/' + name + '">' + name + '</a>'
  end

  def save!(content)
    File.open(@fname,"w+") { |f| f.write(content) }
  end

  def destroy!
    File.delete(@fname)
  end
end


class SimpleWiki < Sinatra::Base
  configure do
    set :markdown, :layout_engine => :erb
    set :views, Page.dir
  end

  get '/' do
    @edit = true
    @page = Page.new('homepage')
    markdown @page.title.to_sym
  end

  get '/contents' do
    contents = Page.list.each_with_object([]) do |p,arr|
      arr << "<li>#{Page.new(p).to_link}</li>"
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
      arr << "<li>#{page.to_link}</li>" if page.raw.match %r/#{params[:q]}/i
    end.join
    erb "<h1>Search results for &quot;#{params[:q]}&quot;</h1><ul>" + results + '</ul>'
  end

  get '/new' do
    erb :new
  end

  get '/new/:page' do |page|
    redirect "/#{page}" if Page.new(page).exists?
    @newname = page
    erb :new
  end

  post '/save' do
    redirect '/' if params[:slug].empty? or params[:content].empty?
    @page = Page.new(params[:slug])
    @page.save!(params[:content])
    redirect @page.title.to_sym
  end

  get '/edit/:page' do |page|
    @slug = page
    @content = Page.new(@slug).raw
    erb :edit
  end

  get '/:page' do |page|
    @page, @edit = Page.new(page), true
    redirect "/new/#{page}" unless @page.exists?
    markdown @page.title.to_sym
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
