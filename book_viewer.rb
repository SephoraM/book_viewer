require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"

before do
  @contents = File.readlines('data/toc.txt')
end

helpers do
  def in_paragraphs(text)
    text.split(/\n\n/).map.with_index
  end
end

helpers do
  def highlight(paragraph, query)
    bolded_query = "<strong>#{query}</strong>"
    paragraph.gsub(query, bolded_query)
  end
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def paragraphs_matching(contents, query)
  paragraphs = []
  ids = []
  contents.split(/\n\n/).each_with_index do |paragraph, index|
    if paragraph.include?(query)
      paragraphs << paragraph
      ids << index
    end
  end
  [paragraphs, ids]
end

def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    paragraphs, ids = paragraphs_matching(contents, query)

    unless ids.empty?
      results << { number: number, name: name,
                   ids: ids, paragraphs: paragraphs }
    end
  end

  results
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  @title = "Chapter #{number}: #{@contents[number - 1]}"

  redirect "/" unless (1..@contents.size).cover? number

  filename = "data/chp#{number}.txt"
  @chapter = File.read(filename)

  erb :chapter
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end
