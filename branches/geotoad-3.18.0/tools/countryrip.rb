#!/usr/bin/env ruby
# Processes the Hide/Seek page to grab countries/state names.
# $Id$

codeType='unknown'

puts "$idHash = Hash.new"
$stdin.each_line { |line|
  if (line =~ /\<select id=\".*?\" name=\"(.*?)\"/)
    codeType=$1
    #puts "#{codeType} - #{line}"
    puts "$idHash[\'#{codeType}\'] = Hash.new"
  end
  line.scan(/OPTION VALUE=(\d+)\>(.*?\w)\s*\<\/OPTION/) { |num, name|
    name.downcase!
    name.gsub!('\*', '')
    name.gsub!('\s+$', '')
    puts "$idHash[\'#{codeType}\'][\'#{name}\']=#{num}"
  }
}