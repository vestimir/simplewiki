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

def read_file(file)
  data = []
  File.open(file, 'r').each_line do |l|
    data << l
  end
  data.join "\n"
end

def write_file(file, data)
  File.open(file, 'w') { |f| f.write(data) }
end

get '/' do
  @slug = 'homepage'
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

get '/:page/edit' do
  @page = read_file(CONTENT + params[:page] + '.md')
  @slug = params[:page]
  erb :edit
end

post '/:page/edit' do
  @content = params[:content]
  write_file(CONTENT + params[:page] + '.md', @content)
  redirect to("/#{params[:page]}")
end

get '/:page' do
  @slug = params[:page]
  begin
    markdown params[:page].to_sym
  rescue
    #TODO: why no layout?
    erb '<h1>Page Not Found</h1>'
  end
end
