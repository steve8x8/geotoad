# $Id: details.rb,v 1.10 2002/08/05 03:38:51 strombt Exp $ require 'cgi'

class CacheDetails < Common
	@@baseURL="http://www.geocaching.com/seek/cache_details.aspx?ID="

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
		fetch(@waypointHash[wid]['sid'])
	end

	def fullURL(id)
		url = @@baseURL + id.to_s + "&log=y&decrypt="
	end

	# fetches by geocaching.com sid
	def fetch(id)
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
				@waypointHash[wid]['latwritten'] = $1 + $2 + " " + $3
				@waypointHash[wid]['lonwritten'] = $4 + $5 + " " + $6
                debug "got written lan/lon: "
            end

            if line =~ /\<span id=\"ErrorText\">(.*?)\<\/span\>/
                @waypointHash[wid]['warning'] = $1
                debug "got a warning: #{$1}"
            end

			if line =~ /\<span id=\"Hints\"\>(.*?)\</
					@waypointHash[wid]['hint'] = $1
                    debug "got hint"
            end

            #if line =~ /lnkTravelBugs/
            #        @waypointHash[wid]['travelbug'] = 'Travel Bug!'
            #        debug "#{wid} has travelbug"
            #end
		}


		# this data is all on one line, so we should just use scan and forget reparsing.
		if (wid)
            debug "we have a wid, who are the visitors..."
			#<A HREF="/profile/default.asp?A=47159">bykenut </A></strong>
			data.scan (/A=\d+\"\>(.*?)\<\/A\>\<\/strong\>/) {
				debug "visitor to #{wid}: #{$1}"
				@waypointHash[wid]['visitors'].push($1)
			}

            # these are multi-line matches, so they are out of the scope of our
            # next
            if data =~ /id=\"ShortDescription\"\>(.*?)\<\/span\>/m
                debug "found short desc: [#{$1}]"
                @waypointHash[wid]['details'] = $1
            end

            if data =~ /id=\"LongDescription\"\>(.*?)\<\/span\><\/BLOCKQUOTE\>/m
				details =  @waypointHash[wid]['details'] << "details: " << $1
				details.gsub!("\<.*?\>", " *")
				details.gsub!("\r\n", " ")
                # MS HTML crap
                details.gsub!("style=\".*?\"", "")
                details.gsub!("\<i.*?\>", "")
				details.gsub!("(\W)  (\W)", "$1")
                details.gsub!(/\* +\*/, "*")
                details.gsub!(/ +/, " ")
				debug "got details: [#{details}]"
				@waypointHash[wid]['details'] = details
            end
		end  # end wid check.
	end  # end function
end  # end class

