# encoding: utf-8
require 'rdiscount'

class Page
  attr_reader :name

  def Page.dir
    File.join(File.dirname(__FILE__),'content')
  end

  def Page.list
    Dir.entries(Page.dir).reject! {|f| f.start_with?('.') }.map { |i|
      i.chomp('.md')
    }.compact.sort_by {|c|
        File.stat(File.join(Page.dir, "#{c}.md")).mtime
      }.reverse
  end

  def initialize(name)
    @name = name
    @fname = File.join(Page.dir,"#{self.title}.md")
  end

  def title
    name.gsub(" ", "_").downcase
  end

  def exists?
    File.exists?(@fname) and not File.basename(@fname).start_with?('.')
  end

  def raw
    File.new(@fname).read
  end

  def to_html
    RDiscount.new(self.raw).to_html
  end

  def save!(content)
    File.open(@fname,"w+") { |f| f.write(content) }
  end

  def destroy!
    File.delete(@fname) if File.exists?(@fname)
  end
end
