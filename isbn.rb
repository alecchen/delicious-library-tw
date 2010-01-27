require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'pp'

keyword = '9789861036038'

# search result
base_url = 'http://lib.ncl.edu.tw'
url = base_url + '/cgi-bin/isbnget?OPT=BOOK.B&TYPE=S&PGNO=1&SEL.CL=&FNM=S&TOPICS1=BN&SEARCHSTR1=' + 
    keyword + '&BOL1=AND&TOPICS2=TI&SEARCHSTR2=&BOL2=AND&TOPICS3=TI&SEARCHSTR3=&PAGELINE=10'
puts url

# book page
doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'))
link = doc.xpath('//a').first
exit unless link

url = base_url + link[:href]
puts url

doc = Nokogiri::HTML(open(url, 'User-Agent' => 'Mac Mozilla'), nil, 'big5')
author, publisher, edition = doc.xpath('//table[@width="100%"][1]//tr//td[2]').collect { |data| data.content }
title = doc.xpath('//a[@name="TOP"]//b').text.gsub(/\s+/, '')
title = title.sub(/【/, '')
title = title.sub(/】/, '')

authors = author.split(/\s*;\s*/)

data = {}
doc.xpath('//table[@width="100%"][2]//tr').each do |item| 
    info = item.at_xpath('.//td[2]').content.split(/\(|\)|：/)
    isbn = info[0]
    binding = info[-1]
    title = "#{title} #{info[1]}" if info.count == 3
    next unless isbn =~ /\d/

    pages, size, price = [3,4,5].collect { |i| item.at_xpath(".//td[#{i}]").content.match(/\d+/).to_a[0] }
    pdate = item.at_xpath('.//td[6]').content.split('/')
    publication_date = "%d/#{pdate[1]}" % (pdate[0].to_i + 1911)

    isbn.gsub!(/-/, '')

    data[isbn] = {
        :title => title,
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

puts data

# cover
# 1 http://findbook.tw
# http://findbook.tw/book/1565923065/basic
#   
# 2 http://www.books.com.tw/
# http://search.books.com.tw/exep/prod_search.php?cat=all&key=9861122931
# http://search.books.com.tw/exep/prod_search_redir.php?key=9861122931&area=mid&item=0010227207
#    
# 3 http://www.kingstone.com.tw/Default.asp
# 4 http://www.2books.com.tw/2hbs/index.php (for second hand books)
