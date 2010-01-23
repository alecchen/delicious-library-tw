require 'rubygems'
require 'sinatra'
require 'haml'
require 'nokogiri'
require 'open-uri'
require 'isbn/tools'

get '/onca/xml' do
  isbn10 = '9573481413' #params[:ItemId] || params[:Keywords]
  @isbn10 = isbn10
  puts "isbn10 = #{isbn10}"

  isbn13 = "978#{isbn10}"
  check_digit = ISBN_Tools.compute_isbn13_check_digit(isbn13)
  isbn13[-1] = check_digit
  @isbn13 = isbn13
  puts "isbn13 = #{isbn13}"

  url = "http://findbook.tw/book/#{isbn13}/basic"
  @url = url
  puts url

  doc = Nokogiri::HTML(open(url))
  doc.xpath('//div[@class="book-profile"]').each do |info|

    title = info.at_xpath('.//h1')
    @title = title.content
    puts title.content

    image = info.at_xpath('.//img')
    @image = image[:src]
    puts image[:src]

    p = info.xpath('.//p')
    author, publisher, publication_date = p[0].content.scan(/作者：(.+), 出版社：(.+), 出版日期：(.+)/)[0]
    authors = author.split(',')
    @authors = authors
    @publisher = publisher
    @publication_date = publication_date

    authors.each {|x| puts "auther = #{x.strip}"}
    puts "publisher = #{publisher}"
    puts "publication_date = #{publication_date}"

    price = p[1].content.scan(/定價\s*(\d+)\s*元/)
    @price = price
    puts "price = #{price}"
  end
  
  content_type 'text/xml', :charset => 'utf-8'
  haml :index
end
