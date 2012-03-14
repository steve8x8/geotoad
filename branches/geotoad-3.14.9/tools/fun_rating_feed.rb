#!/usr/bin/env ruby
# $Id$
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '../lib')

require 'shadowget'
require 'auth'
$debugMode = 0

# If passed a URL to a geocache, this tool downloads all comments
# and outputs them in a format that can be appended to the funfactor data
# by appending it to ../data/boring.txt and ../data/fun.txt appropriately.

# NOTE: You still must use fun_rating_create_data.rb to update the analysis
# database from these .txt files.

CACHE_SECONDS = 86400 * 14

class FunRatingFeed
  include Auth

  def get_uri(uri)
    http = ShadowFetch.new(uri)
    http.cookie = loadCookie()
    http.localExpiry = CACHE_SECONDS
    http.maxFailures = 5
    results = http.fetch
    return results
  end

  def manipulate_uri_options(uri)
    uri.gsub('log=n&','log=y&')
    uri.gsub('decrypt=n&','decrypt=y&')
    if uri !~ /log=/
      uri += '&log=y'
    end
    if uri !~ /decrypt=/
      uri += '&decrypt=y'
    end
    return uri
  end

  def parse_uri(uri)
    data = get_uri(manipulate_uri_options(uri))
    parse_comments(uri, data)
  end

  def parse_comments(uri, data)
    creator = nil
    id = nil
    name = nil
    if data =~ /Log in to view this page/m
      puts "Need to login for: #{uri}"
      return nil
    end

    data.split('\n').each do |line|
      if line =~ /(GC\w+) (.*?) \(.*? by (.*)/
        id = $1
        name = $2
        creator = $3
        name = name.gsub("'", '').chomp
        creator = creator.gsub("'", '').chomp
        puts "#{id}: "
        puts "  name: '#{name}'"
        puts "  url: #{uri}"
        puts "  creator: '#{creator}'"
        puts "  comments: "
      end
  	end
	
	  if not creator:
	    puts "# UNPARSEABLE: {uri}"
	  end

  	visitors = [creator]
  	comments = []
  	data.scan(/icon_(\w+)\.\w+\" title=\"(.*?)\".*? by \<a href=.*?\>(.*?)\<.*?\)\<br \/\>\<br \/\>(.*?)\<br \/\>\<br \/\>/) do |icon, type, user, comment|
      # <tr><td class="AlternatingRow"><strong><img src="http://www.geocaching.com/images/icons/icon_smile.gif"
      # title="Found it" 
      # />&nbsp;September 19, 2008 by <a href="/profile/?guid=dd9d6eb1-3aea-4167-ac94-621898469f73"
      # id="53331610">Bellevan</a></strong> (565 found)<br /><br />We had to expand our search to
      # find this one, but then we were victorious!  Took the gecko, although I told my son it was
      # a salamander as this is his school mascot.  :)  TFTH!<br /><br /><small><    
      visitors << user
      if user == creator or icon == 'remove' or icon == 'disabled' or icon == 'greenlight' or icon == 'maint' or icon == 'note'
        next
      end
#      puts "COMMENT: #{comment}"
      comment.gsub!(/\<.*?\>/, ' ')
      comment.gsub!(/This entry was.*/, '') 
      comment.gsub!(/\[last edit:.*/, '') 
      comment.gsub!(/\s+/, ' ')
      comment.gsub!(/^\s+/, '')
      comment.gsub!(/\s+$/, '')
      comments << comment
    end
  
    comments.each do |comment|
      visitors.each do |visitor|
        comment.gsub!(visitor, '')
        comment.gsub!(visitor.upcase, '')
        comment.gsub!(visitor.downcase, '')
      end
    
      comment.gsub!(/(\w[.,])(\w\w)/, '\1 \2')
      comment.gsub!(/\d.*?\s/, ' ')
      comment.gsub!(/\w+\d$/, '')
      comment.gsub!(/\d.*$/, '')
      comment.gsub!(/[\'\"]/, '')
      comment.gsub!(/\!+/, '!')
      comment.gsub!(/[\[:\]\>\<\=\-\)\(\/\*\#\~\%\+]/, ' ')
      # Remove last paragraph (signature)
      comment.gsub!(/\s+/, ' ')
      comment.gsub!(/ $/, '')
      comment.gsub!(/^\W+/, '')
      comment.gsub!(/\<p\>.{4,30}$/, '')
      comment.gsub!(/\<br\>.{4,30}$/, '')
      if comment.length > 2
        puts "  - '#{comment}'"
      end
    end
    puts ""  
  end
end

# Sample URL: http://www.geocaching.com/seek/cache_details.aspx?wp=GCZT23&log=y&decrypt=y
feed = FunRatingFeed.new()
feed.parse_uri(ARGV[0])
