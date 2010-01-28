#中文數字和阿拉伯數字之間的互相轉換
#  比如: 138 <=> 一百三十八
#
#作者: 半瓶墨水 http://www.2maomao.com/blog/
$KCODE = 'u'
require 'jcode'
require 'iconv'

$cn_nums = %w{零 一 二 三 四 五 六 七 八 九}
$cn_decs =   %w{十 百 千 萬 十 百 千 億}
$conv = Iconv.new('gbk' , 'utf-8')

$cn_nums_map = {
  '〇' => 0 ,
  '一' => 1 ,
  '二' => 2 ,
  '三' => 3 ,
  '四' => 4 ,
  '五' => 5 ,
  '六' => 6 ,
  '七' => 7 ,
  '八' => 8 ,
  '九' => 9 ,

  '零' => 0 ,
  '壹' => 1 ,
  '貳' => 2 ,
  '參' => 3 ,
  '肆' => 4 ,
  '伍' => 5 ,
  '陸' => 6 ,
  '柒' => 7 ,
  '捌' => 8 ,
  '玖' => 9 ,

  '貮' => 2 ,
  '兩' => 2 ,
}

$cn_decs_map = {
  '個' => 1 ,
  '十' => 10 ,
  '拾' => 10 ,
  '百' => 100 ,
  '佰' => 100 ,
  '千' => 1000 ,
  '仟' => 1000 ,
  '萬' => 10000 ,
  '萬' => 10000 ,
  '億' => 100000000 ,
  '億' => 100000000 ,
  '兆' => 1000000000000 ,
}

def uputs ( str )
  puts $conv.iconv( str )
end

class NumCnConv
  private
  def digit2cn ( d )
    $cn_nums [ d - '0' [ 0 ]]
  end
  def is_all_zero ( str )
    return str == ( '0' * str . size )
  end

  public
  def num2cn ( num )
    str = num . to_s
    #        print str + ":"
    result = []
    str = str . reverse
    zero_count = 0       #zero_count after last non-zero digit
    index = 0            #the index for the numbers
    first_zero = true    #don't need to insert 零 for numbers like /[1-9]+0+/
    str_wan_yi = nil     #insert 萬 & 億 when needed
    while index < str . size do #3 0423 4829
      d = str [ index ]
      #puts "index = #{index} (#{d.chr})"
      if ( d - '0' [ 0 ] > 0 )
        if zero_count > 0
          zero_count = 0
          result << digit2cn( '0' [ 0 ] ) if ! first_zero
          if str_wan_yi != nil
            result << str_wan_yi
            str_wan_yi = nil
          end
        end
        result << $cn_decs [ ( index - 1 ) % ( $cn_decs . size ) ] if index > 0
        result << digit2cn( d )
        first_zero = false
      else
        if ( index > 0 && ( index % 4 ) == 0 && ! is_all_zero( str [ index , 4 ] ) )
          str_wan_yi = $cn_decs [ ( index - 1 ) % ( $cn_decs . size ) ]
        end
        zero_count += 1
      end
      index += 1
    end
    if zero_count > 0
      zero_count = 0
      result << digit2cn( '0' [ 0 ] )
    end
    result = result . reverse

    res = result . join
    if res =~ /^一十/
      res = res [ '一' . size , res . size - '一' . size ]
    end
    #        uputs res
    return res
  end

  def cn2num ( str )
    #remove 零
    num_str = ''
    last = nil
    str.scan( /./u ) do | c |
      if ( ! $cn_nums_map [ c ] && ! $cn_decs_map [ c ] )
        uputs " #{ str }   是個錯誤的數字串"
        return nil
      end
    num_str += c if c != '零'
    last = c
    end
    if num_str =~ /^十/
      num_str = '一' + num_str
    end

    sums = []
    temp_sum = 0
    last_num = 0
    num_str.scan( /./u ) do | ch |
      if num = $cn_nums_map [ ch ]
        last_num = num
      else
        dec = $cn_decs_map [ ch ]
        if dec < 10000
          temp_sum += last_num * dec
        else
          #find back for the one that exceeds current dec
          sums . each_with_index do | x , i |
            if x < dec * 10 #10 is here for situation like 兩億億
              sums [ i ] = x * dec
            else
              break
            end
          end
          temp_sum += last_num
          sums << temp_sum * dec
          temp_sum = 0
        end
        last_num = 0
      end
    end
    sums << temp_sum + last_num

    sum = 0
    sums . each do | x |
      sum += x
    end
    return sum
  end
end 

#myconv = NumCnConv.new
#puts myconv.cn2num('25') 
