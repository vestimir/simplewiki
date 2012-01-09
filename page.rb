# encoding: utf-8

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
    File.delete(@fname) if File.exists?(@fname)
  end
end
