#!/usr/bin/env ruby

def check_word(buf, check_word)
  # 正規表現を使って単語を抽出する
  words = buf.scan(/\b\w+\b/)

  # 抽出した単語を表示する
  words.each do |word|
    #puts "#{word} == #{check_word}"
    # 完全一致
    return true if word == check_word
  end
  return false
end

if $0 == __FILE__
  File.read(ARGV[0]).each_line do |line|
    puts line
    if check_word(line, ARGV[1])
      puts "ok"
    end
  end
end
