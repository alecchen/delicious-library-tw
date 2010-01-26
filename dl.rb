require 'rubygems'
require 'sinatra'
require 'haml'
require 'nokogiri'
require 'open-uri'
require 'isbn/tools'

get '/onca/xml' do
  isbn10 = params[:ItemId] || params[:Keywords]

  isbn13 = "978#{isbn10}"
  check_digit = ISBN_Tools.compute_isbn13_check_digit(isbn13)
  isbn13[-1] = check_digit

  # search result
  base_url = 'http://lib.ncl.edu.tw'
  url = base_url + '/cgi-bin/isbnget?OPT=BOOK.B&TYPE=S&PGNO=1&SEL.CL=&FNM=S&TOPICS1=BN&SEARCHSTR1=' + 
    isbn13 + '&BOL1=AND&TOPICS2=TI&SEARCHSTR2=&BOL2=AND&TOPICS3=TI&SEARCHSTR3=&PAGELINE=10'

  # book page
  doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
  link = doc.xpath('//a').first
  exit unless link

  url = base_url + link[:href]
  doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'), nil, 'big5')
  author, publisher, edition = doc.xpath('//table[@width="100%"][1]//tr//td[2]').collect { |data| data.content }
  title = doc.xpath('//a[@name="TOP"]//b').text.gsub(/[【】\s]+/, '')

  authors = author.split(/\s*;\s*/)

  data = {}
  doc.xpath('//table[@width="100%"][2]//tr').each do |item| 
    isbn, volume, binding = item.at_xpath('.//td[2]').content.split(/\(|\)|：/)
    next unless isbn =~ /\d/

    pages, size, price = [3,4,5].collect { |i| item.at_xpath(".//td[#{i}]").content.match(/\d+/).to_a[0] }
    pdate = item.at_xpath('.//td[6]').content.split('/')
    publication_date = "%d/#{pdate[1]}" % (pdate[0].to_i + 1911)

    isbn.gsub!(/-/, '')

    data[isbn] = {
      :title => title,
      :url => "http://findbook.tw/book/#{isbn13}/basic",
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
      :volume => volume,
    }
  end

  @data = data[isbn13]

  # get cover from findbook
  image_url = "http://static.findbook.tw/image/book/#{isbn13}/large"
  `rm public/images/large.jpg; wget #{image_url}; mv large public/images/large.jpg`

  # render page
  content_type 'text/xml', :charset => 'utf-8'
  haml :index
end
