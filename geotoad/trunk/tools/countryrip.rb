#!/usr/local/bin/ruby
# Processes the Hide/Seek page to grab countries/state names.
codeType='unknown'

puts "idLookupHash = Hash.new"
$stdin.each_line { |line|
    if (line =~ /\<select id=\".*?\" name=\"(.*?)\"/)
        codeType=$1
        #puts "#{codeType} - #{line}"
        puts "idLookupHash[\'#{codeType}\'] = Hash.new"
    end
    line.scan(/OPTION VALUE=(\d+)\>(.*?)\<\/OPTION\>/) {
            num=$1
            name=$2
            name.gsub!('\*', '')
            name.gsub!('\s+$', '')
            puts "idLookupHash[\'#{codeType}\'][\'#{name}\']=#{num}"
    }
}
