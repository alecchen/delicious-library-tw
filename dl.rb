require 'rubygems'
require 'sinatra'
require 'nokogiri'
require 'open-uri'
require 'haml'
require 'isbn/tools'

get '/onca/xml' do
  #isbn10 = params[:ItemId] || params[:Keywords]
  #puts "isbn10 = #{isbn10}"

  #isbn13 = "978#{isbn10}"
  #puts "isbn13 = #{isbn13}"

  #check_digit = ISBN_Tools.compute_isbn13_check_digit(isbn13)
  #isbn13[-1] = check_digit
  #@isbn13 = isbn13
  #puts "isbn13 = #{isbn13}"

  #url = "http://findbook.tw/book/#{isbn13}/basic"
  #puts url

  #doc = Nokogiri::HTML(open(url))
  #doc.xpath('//div[@class="book-profile"]').each do |info|

    #title = info.at_xpath('.//h1')
    #@title = title.content
    #puts @title

    #image = info.at_xpath('.//img')
    #@image_url = image[:src]
    #puts @image_url

  #end

  #content_type 'text/xml', :charset => 'utf-8'
  #haml :index
  content_type 'text/xml', :charset => 'utf-8'
  lines = open('6.xml').readlines
  "#{lines}"
end
