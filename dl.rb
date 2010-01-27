require 'rubygems'
require 'sinatra'
require 'haml'
require 'nokogiri'
require 'open-uri'
require 'isbn/tools'

get '/onca/xml' do
  keyword = params[:ItemId] || params[:Keywords]
  isbn10, isbn13 = isbn10_13(keyword)

  # search result
  # if keyword =~ /^\d+$/ => isbn search, else => title search
  base_url = 'http://lib.ncl.edu.tw'
  url = base_url + '/cgi-bin/isbnget?OPT=BOOK.B&TYPE=S&PGNO=1&SEL.CL=&FNM=S&TOPICS1=BN&SEARCHSTR1=' + 
    isbn13 + '&BOL1=AND&TOPICS2=TI&SEARCHSTR2=&BOL2=AND&TOPICS3=TI&SEARCHSTR3=&PAGELINE=10'

  # book page
  # TODO: multiple search results
  # TODO: TITLE search
  doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
  link = doc.xpath('//a').first
  exit unless link

  url = base_url + link[:href]
  doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'), nil, 'Big5-HKSCS')
  author, publisher, edition = 
    doc.xpath('//table[@width="100%"][1]//tr//td[2]').collect { |data| data.content }
  title = doc.xpath('//a[@name="TOP"]//b').text.gsub(/\s+/, '')
  title = title.sub(/【/, '')
  title = title.sub(/】/, '')
  puts "title = #{title}"

  authors = author.split(/\s*;\s*/)

  data = {}
  doc.xpath('//table[@width="100%"][2]//tr').each do |item| 
    info = item.at_xpath('.//td[2]').content.split(/\(|\)|：/)
    isbn = info[0]
    binding = info[-1]
    mytitle = title
    mytitle += " #{info[1]}" if info.count == 3
    next unless isbn =~ /\d/

    pages, size, price = [3,4,5].collect { |i| item.at_xpath(".//td[#{i}]").content.match(/\d+/).to_a[0] }
    pdate = item.at_xpath('.//td[6]').content.split('/')
    publication_date = "%d/#{pdate[1]}" % (pdate[0].to_i + 1911)

    isbn.gsub!(/-/, '')

    data[isbn] = {
      :title => mytitle,
      :url => "http://findbook.tw/book/#{isbn13}/basic",
      :binding => binding,
      :isbn13 => isbn13,
      :isbn10 => isbn10,
      :authors => authors,
      :publisher => publisher,
      :edition => edition,
      :isbn => isbn,
      :pages => pages,
      :size => size,
      :price => price,
      :publication_date => publication_date,
    }
  end

  @data = data[isbn13]

  url = "http://search.books.com.tw/exep/prod_search.php?cat=all&key=#{isbn13}"

  doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
  link = doc.xpath('//div[@class="conten"]//a').first

  if link
    url = link[:href]
    puts url
    doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
    img = doc.xpath('//div/img').first
    @data[:image_url] = img[:src]
    puts img[:src]
  end

  # render page
  content_type 'text/xml', :charset => 'utf-8'
  haml :index
end

helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def isbn10_13(keyword)
    isbn10 = ''
    isbn13 = ''

    if keyword.length == 10
      isbn10 = keyword
      isbn13 = '978' + isbn10
      check_digit = ISBN_Tools.compute_isbn13_check_digit(isbn13)
      isbn13[-1] = check_digit
    else
      isbn13 = keyword
      isbn10 = isbn13[3..12]
      check_digit = ISBN_Tools.compute_isbn10_check_digit(isbn10)
      isbn10[-1] = check_digit
    end

    return isbn10, isbn13
  end
end
