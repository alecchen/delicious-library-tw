require 'rubygems'
require 'sinatra'
require 'haml'
require 'nokogiri'
require 'open-uri'
require 'isbn/tools'
require 'lib/numconv'
require 'uri'

get '/onca/xml' do
  keyword = params[:ItemId] || params[:Keywords]
  @data = []

  # isbn search
  if keyword =~ /^\d{10,13}/
    @data = get_data_from_isbn(keyword)
  # keyword search
  else
    @data = get_data_from_keyword(keyword)
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

  def get_data_from_keyword(keyword)
    keyword = keyword.split.join('+')
    url = URI.escape("http://search.books.com.tw/exep/prod_search.php?cat=all&key=#{keyword}")
    doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))

    result = doc.xpath('//table[@class="article"]//tr').collect do |item|
      data = {}

      title = item.at_xpath('.//h3//a')[:title]
      title.gsub!(/\s*\(/, ' ')
      title.gsub!(/\)/, '')

      book_url = item.at_xpath('.//h3//a')[:href]
      isbn = book_url.scan(/\d+/)[0]

      info = item.xpath('.//h4//a')
      authors = [info[0][:title]]
      publisher = info[1][:title]
      publication_date = item.at_xpath('.//h4').text.split('：').last

      #price = item.at_xpath('.//h4[@class="mh"]//strike').content.scan(/\d+/)[0]

      image = item.at_xpath('.//img')
      image_url = image[:src].split('&').first
      image_url += '&width=200&quality=100'

      data = {
        :title => title,
        :url => book_url,
        :isbn13 => isbn,
        :isbn10 => isbn,
        :authors => authors,
        :publisher => publisher,
        :isbn => isbn,
        :image_url => image_url,
        :publication_date => publication_date,
        #:price => price,
      }

      data
    end

    return result
  end

  def get_data_from_isbn(isbn)
    isbn10, isbn13 = isbn10_13(isbn)

    # search result
    base_url = 'http://lib.ncl.edu.tw'
    url = base_url + '/cgi-bin/isbnget?OPT=BOOK.B&TYPE=S&PGNO=1&SEL.CL=&FNM=S&TOPICS1=BN&SEARCHSTR1=' + 
      isbn13 + '&BOL1=AND&TOPICS2=TI&SEARCHSTR2=&BOL2=AND&TOPICS3=TI&SEARCHSTR3=&PAGELINE=10'

    # book page
    doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
    link = doc.xpath('//a').first
    return unless link

    url = base_url + link[:href]
    doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'), nil, 'Big5-HKSCS')
    author, publisher, edition = 
      doc.xpath('//table[@width="100%"][1]//tr//td[2]').collect { |data| data.content }
    title = doc.xpath('//a[@name="TOP"]//b').text.gsub(/\s+/, '')
    title = title.sub(/【/, '')
    title = title.sub(/】/, '')

    authors = author.split(/\s*;\s*/)

    data = {}
    doc.xpath('//table[@width="100%"][2]//tr').each do |item| 
      info = item.at_xpath('.//td[2]').content.split(/\(|\)|：/)
      isbn = info[0]
      binding = info[-1]
      mytitle = title
      volume = info[1]

      if info.count == 3
        if volume.length > 6 && volume !~ /\d+/
          myconv = NumCnConv.new
          volume = volume.scan(/[一二三四五六七八九十]+/).first
          volume = myconv.cn2num(volume) 
          volume = "第#{volume}集"
        end
        mytitle += volume
      end

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

    result = data[isbn13]

    # search image
    url = "http://search.books.com.tw/exep/prod_search.php?cat=all&key=#{isbn13}"
    doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
    image = doc.xpath('//div[@class="book"]//img').first

    if image
      image_url = image[:src].split('&').first
      image_url += '&width=200&quality=100'
      result[:image_url] = image_url
    end

    return [result]
  end
end
