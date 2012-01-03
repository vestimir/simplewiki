# encoding: utf-8

require 'sinatra'
require 'rdiscount'

module WikiHelpers
  def read_dir(dir)
    Dir.entries(dir).map {|i| i unless $excl.include?(i) or i.match(%r/^\./i)}.compact
  end
end

class SimpleWiki < Sinatra::Base
  configure do
    $excl = ['.', '..', 'layout.erb']
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

  get '/:page' do
    begin
      markdown params[:page].to_sym
    rescue Exception => e
      erb "<p><div class='alert-message'>#{e.to_s}</div></p>"
    end
  end
end  
