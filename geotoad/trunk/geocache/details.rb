# $Id: details.rb,v 1.10 2002/08/05 03:38:51 strombt Exp $ require 'cgi'

class CacheDetails < Common
	@@baseURL="http://www.geocaching.com/seek/cache_details.aspx?guid="

	def initialize(data)
		@waypointHash = data
		#fetchAll()
	end

	def waypoints
		@waypointHash
	end

	def baseURL
		@@baseURL
	end

	# fetches by waypoint id
	def fetchWid(wid)
        debug "fetching by #{wid}, converting to #{@waypointHash[wid]['sid']}"
		fetch(@waypointHash[wid]['sid'])
	end

	def fullURL(id)
		url = @@baseURL + id.to_s + "&log=y"
	end

	# fetches by geocaching.com sid
	def fetch(id)
        if ((! id) || (id.length < 1))
            puts "Empty fetch by id, quitting."
            exit
        end

		url = fullURL(id)
		page = ShadowFetch.new(url)
		page.fetch
        if (page.data)
    		parseCache(page.data)
        else
            debug "No data found, not attempting to parse the entry"
        end
	end

	def parseCache(data)
		# find the geocaching waypoint id.
		wid = ''
		data.each { |line|
			if line =~ /\<title\>Cache: \((\w+)\)/
				wid = $1
                debug "wid is #{wid}"

                # fill this in, since it's optional evidentally
                @waypointHash[wid]['details'] = ''
            end
            if line =~ /value=\"([-\+\d\.]+)\" name=lat\>/
                @waypointHash[wid]['latdata'] = $1
				debug "got lat data: #{$1}"
            end
            if line =~ /value=\"([-\+\d\.]+)\" name=lon\>/
                @waypointHash[wid]['londata'] = $1
				debug "got lon data: #{$1}"
            end
			if line =~ /\<font size=\"3\"\>([NW]) (\d+).*? ([\d\.]+) ([NW]) (\d+).*? ([\d\.]+)\<\/STRONG\>/
				@waypointHash[wid]['latwritten'] = $1 + $2 + ' ' + $3
				@waypointHash[wid]['lonwritten'] = $4 + $5 + ' ' + $6
                debug "got written lan/lon: "
            end

            if line =~ /\<span id=\"ErrorText\">(.*?)\<\/span\>/
                warning = $1
                warning.gsub!(/\<.*?\>/, '')
                @waypointHash[wid]['warning'] = warning.dup
                debug "got a warning: #{$1}"
            end

			if line =~ /\<span id=\"Hints\"\>(.*?)\<\/span\>/m
                hint = $1.dup
                hint.gsub!(/\<.*?\>/, '')
				@waypointHash[wid]['hint'] = hint
                debug "got hint: #{hint}"
            end

		}


		# this data is all on one line, so we should just use scan and forget reparsing.
		if (wid)
            debug "we have a wid, who are the visitors..."

            # thanks to Mike Capito for the heads up on the most recent change here.
			#<A NAME="1921710"><A HREF="../profile/?guid=685787d4-3eab-43a0-93c0-9173fd284083">Geo13</A></strong>
			data.scan (/profile\/\?guid=.*?\"\>(.*?)\<\/A\>\<\/strong\>/) {
				puts "visitor to #{wid}: #{$1.downcase}"
				@waypointHash[wid]['visitors'].push($1.downcase)
			}


            # these are multi-line matches, so they are out of the scope of our
            # next
            if data =~ /id=\"ShortDescription\"\>(.*?)\<\/span\>/m
                debug "found short desc: [#{$1}]"
                @waypointHash[wid]['details'] = $1.dup
            end

            if data =~ /id=\"LongDescription\"\>(.*?)\<\/span\><\/BLOCKQUOTE\>/m
                debug "found long desc"
				details =  @waypointHash[wid]['details'] << "  " << $1

                debug "pre-html-process: #{details}"
                # normalize.
				details.gsub!('\r\n', ' ')
				details.gsub!('\r', '')
				details.gsub!('\n', '')

                debug "normalized: #{details}"
                # kill
                details.gsub!(/\<\/li\>/i, '')
                details.gsub!(/\<\/p\>/i, '')
                details.gsub!(/<\/*i\>/i, '')
                details.gsub!(/<\/*body\>/i, '')
                details.gsub!(/<\/*option.*?\>/i, '')
                details.gsub!(/<\/*select.*?\>/i, '')
                details.gsub!(/<\/*span.*?\>/i, '')
                details.gsub!(/<\/*font.*?\>/i, '')
                details.gsub!(/<\/*ul\>/i, '')

                debug "post-html-tags-removed: #{details}"

                # substitute
                details.gsub!(/\<p\>/i, "**")
                details.gsub!(/\<li\>/i, "\n * (o) ")
                details.gsub!(/<\/*b>/i, '')
                details.gsub!(/\<img.*?\>/i, '[img]')
				details.gsub!(/\<.*?\>/, ' *')
                # MS HTML crap
                details.gsub!(/style=\".*?\"/i, '')
                details.gsub!("<", '&lt;')
                details.gsub!(">", "&gt;")

                debug "pre-combine-process: #{details}"

                # combine all the tags we nuked.
                details.gsub!(/ +/, ' ')
                details.gsub!(/\* *\* *\*/, '**')
                details.gsub!(/\* *\* *\*/, '**')
                details.gsub!(/\*\*\*/, '**')

                debug "post-combine-process: #{details}"
                details.gsub!(/^\*/, '')
                details.gsub!(/[\x80-\xFF]/, "\'")
                details.gsub!(/\'+/, "\'")
                # some misc. random crap.


				debug "got details: [#{details}]"
				@waypointHash[wid]['details'] = details
            end
		end  # end wid check.
	end  # end function
end  # end class

