require 'sinatra'

CONTENT = File.dirname(__FILE__) + '/content/'
set :markdown, :layout_engine => :erb
set :views, CONTENT

def read_dir(dir)
    files = []
    Dir.entries(dir).each do |i|
        files << i if not ['.', '..', 'layout.erb'].include? i and not i.match %r/^\./i
    end
    files
end

get '/' do
    markdown :homepage
end

get '/contents' do
    contents = ''
    read_dir(CONTENT).each do |f|
        slug = f.gsub '.md', ''
        contents += '<li><a href="/' + slug + '">' + slug + '</a></li>'
    end
    erb '<h1>Table of Contents</h1><ul>' + contents + '</ul>'
end

get '/:page' do
    begin
        markdown params[:page].to_sym
    rescue
        #why no layout?
        erb '<h1>Page Not Found</h1>'
    end
end
