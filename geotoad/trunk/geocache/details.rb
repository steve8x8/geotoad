

class CacheDetails
    include Common
    include Display

    # This now uses the printable version of the cache data. For now, we get the last 10
    # logs to a cache.
	@@baseURL="http://www.geocaching.com/seek/cache_details.aspx?pf=y&log=y&numlogs=5&decrypt=&guid="

	def initialize(data)
		@waypointHash = data
        @useShadow=1
		#fetchAll()
	end

    def useShadow=(toggle)
        @useShadow=toggle
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
		url = @@baseURL + id.to_s
	end

	# fetches by geocaching.com sid
	def fetch(id)
        if ((! id) || (id.length < 1))
            displayError "Empty fetch by id, quitting."
            exit
        end

		url = fullURL(id)
		page = ShadowFetch.new(url)

		page.fetch
        if (page.data)
    		ret = parseCache(page.data)
        else
            debug "No data found, not attempting to parse the entry"
        end

        # We try to download the page one more time.
        if ret
            return 1
        else
            displayWarning "Could not parse page information for #{@wid}, retrying download"
            sleep(5)
            page.shadowExpiry=1
            page.localExpiry=1
            page.fetch

            if (page.data)
                ret = parseCache(page.data)
            else
                debug "No data found, not attempting to parse the entry"
            end

            if ret
                return 1
            else
                displayWarning "I have failed."
                return nil
            end
        end

	end

	def parseCache(data)
		# find the geocaching waypoint id.
		wid = nil
		data.each { |line|
            # this matches the <title> on the printable pages. Some pages have ) and some don't.
			if line =~  /^\s+(GC[A-Z0-9]+)[) ]/
                # only do it if the wid hasn't been found yet, sometimes pages mention wid's of other caches.
                if (! wid)
                    wid = $1
                    debug "wid is #{wid}"

                    # We give this a predefined value, because some caches have no details!
                    @waypointHash[wid]['details'] = ''
                end
            end

            # latitude in the post form. Used by GPX and other formats
            # [<A HREF="http://www.geocaching.com/map/getmap.aspx?lat=39.14498&lon=-86.22033">view map</A>]</font></span></FONT><br>
			# Regexp rewritten by Scott Brynen for Canadian compatibility
		    if line =~ /getmap\.aspx\?lat=([\d\.-]+)\&lon=([\d\.-]+)/
                @waypointHash[wid]['latdata'] = $1
                @waypointHash[wid]['londata'] = $2
				debug "got digital lat/lon: #{$1} #{$2}"
            end

            # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
            if line =~ /\<font size=\"3\"\>([NWSE]) (\d+).*? ([\d\.]+) ([NWSE]) (\d+).*? ([\d\.]+)\<\/STRONG\>/
                @waypointHash[wid]['latwritten'] = $1 + $2 + ' ' + $3
              	@waypointHash[wid]['lonwritten'] = $4 + $5 + ' ' + $6
              	@waypointHash[wid]['latdata'] = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
              	@waypointHash[wid]['londata'] = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
              	debug "got written lat/lon"
            end


            # why a geocache is closed. It seems to always be the same.
            if line =~ /\<span id=\"ErrorText\">(.*?)\<\/span\>/
                warning = $1
                warning.gsub!(/\<.*?\>/, '')
                @waypointHash[wid]['warning'] = warning.dup
                debug "got a warning: #{warning}"
            end

            # encrypted hint
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

            # We used to include any comments, but with the smile part, we only include founds.
            #icon_smile.gif'>&nbsp;October 12 by <A NAME="2224020"><A HREF="../profile/?guid=5dadabfd-1343-44f2-a3b1-09a4886cb164">
            #           smile.gif'>&nbsp;August 25 by <A NAME="1945173"><A HREF="../profile/?guid=4dda95c7-06b4-42df-8bfa-d936d52a6c57">Jnick</A></strong>

			data.scan(/smile.gif\'\>\&nbsp\;\w+ \d+ by <A NAME=\"\d+\"\>\<A HREF=\"..\/profile\/\?guid=.*?\"\>(.*?)\<\/A/) {
                debug "visitor to #{wid}: #{$1.downcase}"
                @waypointHash[wid]['visitors'].push($1.downcase)
            }


            # these are multi-line matches, so they are out of the scope of our
            # next
            if data =~ /id=\"ShortDescription\"\>(.*?)\<\/span\>/m
                debug "found short desc: [#{$1}]"
                shortdesc = $1
                shortdesc.gsub!(/[\x80-\xFF]/, "\'")		# high ascii
                shortdesc.gsub!(/\&#\d+\;/, "\'")		# high ascii in entity format
                shortdesc.gsub!(/\'+/, "\'")
                shortdesc.gsub!(/^\*/, '')
                @waypointHash[wid]['details'] = CGI.unescapeHTML(shortdesc)
            end

            if data =~ /id=\"LongDescription\"\>(.*?)\<\/span\><\/BLOCKQUOTE\>/m
                debug "found long desc"
                details =  @waypointHash[wid]['details'] << "  " << $1

                debug "pre-html-process: #{details}"
                # normalize, but work around the ruby 1.8.0 warnings.
                details.gsub!(/#{'\r\n'}/, ' ')
                details.gsub!(/#{'\r'}/, '')
                details.gsub!(/#{'\n'}/, '')

                debug "normalized: #{details}"
                # rip some tags out.
                details.gsub!(/\<\/li\>/i, '')
                details.gsub!(/\<\/p\>/i, '')
                details.gsub!(/<\/*i\>/i, '')
                details.gsub!(/<\/*body\>/i, '')
                details.gsub!(/<\/*option.*?\>/i, '')
                details.gsub!(/<\/*select.*?\>/i, '')
                details.gsub!(/<\/*span.*?\>/i, '')
                details.gsub!(/<\/*font.*?\>/i, '')
                details.gsub!(/<\/*ul\>/i, '')
                details.gsub!(/style=\".*?\"/i, '')

                debug "post-html-tags-removed: #{details}"

                # substitute
                details.gsub!(/\<p\>/i, "**")
                details.gsub!(/\<li\>/i, "\n * (o) ")
                details.gsub!(/<\/*b>/i, '')
                details.gsub!(/\<img.*?\>/i, '[img]')
                details.gsub!(/\<.*?\>/, ' *')
                debug "pre-combine-process: #{details}"

                # combine all the tags we nuked. These regexps
                # could probably be cleaned up pretty well.
                details.gsub!(/ +/, ' ')
                details.gsub!(/\* *\* *\*/, '**')
                details.gsub!(/\* *\* *\*/, '**')		# unnescesary
                details.gsub!(/\*\*\*/, '**')
                details.gsub!(/\* /, '*')
                debug "post-combine-process: #{details}"
                details.gsub!(/[\x80-\xFF]/, "\'")		# high ascii
                details.gsub!(/\&#\d+\;/, "\'")			# high ascii in entity format
                details.gsub!(/\&nbsp\;/, " ")			# unescapeHTML seems to ignore.
                details.gsub!(/\'+/, "\'")			# multiple apostrophes
                details.gsub!(/^\*/, '')			# lines that start with *

		# kill the last space, which makes the CSV output nicer.
		details.gsub!(/ $/, '')

                # convert things into plain text.
                details = CGI.unescapeHTML(details);

                debug "got details: [#{details}]"
                @waypointHash[wid]['details'] = details
            end
        end  # end wid check.

        # This checks to see if it's a geocache that at least has coordinates to mention.
        if wid && @waypointHash[wid]['latwritten']
            return 1
        else
            return nil
        end

	end  # end function
end  # end class

