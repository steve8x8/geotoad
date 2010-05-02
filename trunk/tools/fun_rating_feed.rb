#!/usr/bin/ruby
# $Id$

require 'open-uri'

uri=ARGV[0]
uri.gsub('pf=n&','pf=y&')
uri.gsub('log=n&','log=y&')
uri.gsub('decrypt=n&','decrypt=y&')

if uri !~ /pf=/
  uri += '&pf=y'
end
if uri !~ /log=/
  uri += '&log=y'
end
if uri !~ /decrypt=/
  uri += '&decrypt=y'
end

#puts uri
open(uri).readlines.each do |line|
	
  if line =~ /^\s+(GC\w+) (.*) \(/
    id=$1
    name=$2
    puts "#{id}: "
    puts "  name: #{name}"
    puts "  url: #{uri}"
    puts "  comments: "
  end
	
  # (45 found)<br /><br />Very creative and a fun change of pace from average caches.</td>
  line.scan(/\d+ found\)\<br \/\>\<br \/\>(.*?)\<\/td\>/) do |match|
    string = match.join('')
    string.gsub!(/^\s+/, '')
    string.gsub!(/[\[:\]\>\<\=\-\)\(\/\*]/, ' ')
    string.gsub!(/[\'\"]/, '')
    string.gsub!(/\[This entry was.*/, '') 
    puts "  -  #{string}"
  end
end
