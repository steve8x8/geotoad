

class CacheDetails
    include Common
    include Display

    # This now uses the printable version of the cache data. For now, we get the last 10
    # logs to a cache.
	@@baseURL="http://www.geocaching.com/seek/cache_details.aspx?pf=y&log=y&numlogs=5&decrypt="

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

    # this routine is for compatibility.
    def fetchWid(id)
        fetch(id)
    end

	def fullURL(id)
        if (id =~ /^GC/)
            # If we can look up the guid, use it. It's not actually required, but
            # it behaves a lot more like a standard web browser on the gc.com website.
            if @waypointHash[id]['sid']
                suffix = 'guid=' + @waypointHash[id]['sid'].to_s
            else
                suffix = 'wp=' + id.to_s
            end
        else
             suffix = 'guid=' + id.to_s
        end

        url = @@baseURL + "&" + suffix
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

                    # Set what URL we used as our details source. We do not use baseURL because
                    # some GPX parsers freak if there is a & in this URL.
                    @waypointHash[wid]['url'] = "http://www.geocaching.com/seek/cache_details.aspx?wp=" + wid
                end
            end


            # DUPLICATE OF WHAT SEARCH.RB HAS! Only used for failures and or wid searches.
            # May make in the future have it decide which source is newest: search or details.
            if line =~ /\<span id=\"CacheName\"\>(.*?)\<\/span\>/
                if (! @waypointHash[wid]['name'])
                    @waypointHash[wid]['name'] = $1
                    debug "name was not set, now set to #{$1}"
                end
            end


            # DUPLICATE OF WHAT SEARCH.RB HAS! Only used for failures and or wid searches.
            # May make in the future have it decide which source is newest: search or details.
            if line =~ /\<br\>by (.*?) \[\<A HREF/
                if (! @waypointHash[wid]['creator'])
                    @waypointHash[wid]['creator'] = $1
                    debug "creator was not set, now set to #{$1}"

                end
            end

            if line =~ /\<br\>Size: ([\w ]+)\<br\>/
                @waypointHash[wid]['container'] = $1
                debug "container type is #{$1}"
            end

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

            if line =~ /\<span id=\"CacheLogs\"\>/
                # ratings
                artificialRating = 2

                cnum = 0
                line.scan(/icon_(\w+)\.gif.*?\&nbsp\;(.*?) by \<A NAME=\"(\d+)\"\>\<A HREF=\".*?\"\>(.*?)\<.*?\<br\>(.*?)\<\/font\>/) { |icon, date, id, name, comment|
                    comment.gsub!(/\<.*?\>/, ' ')
                    type = 'unknown'

                    # these are the types that I have seen before in GPX files
                    # Archive (show)       Attended      Didn't find it      Found it
                    # Needs Archived       Note          Other               Unarchive
                    # Webcam Photo Taken   Write note

                    case icon
                        when /smile|happy/
                            type = 'Found it'
                            @waypointHash[wid]['visitors'].push(name.downcase)
                        when 'sad'
                            type = 'Didn\'t find it'
                        when 'note'
                            type = 'Note'
                        when 'remove'
                            type = 'Archive (show)'
                        when 'camera'
                            type = 'Webcam Photo Taken'
                        else
                            type = 'Other'
                    end

                    @waypointHash[wid]["comment#{cnum}Type"] = type.dup
                    @waypointHash[wid]["comment#{cnum}Date"] = date.dup
                    @waypointHash[wid]["comment#{cnum}ID"] = id.dup
                    @waypointHash[wid]["comment#{cnum}Icon"] = icon.dup
                    @waypointHash[wid]["comment#{cnum}Name"] = name.dup
                    @waypointHash[wid]["comment#{cnum}Comment"] = comment.dup

                    artificialRating = artificialRating + determineRating(type, comment)

                    debug "COMMENT #{cnum}: i=#{icon} d=#{date} id=#{id} n=#{name} c=#{comment}"
                    cnum = cnum + 1
                }

                debug "artificialrating = #{artificialRating}"
                @waypointHash[wid]['arating'] = artificialRating
            end

		}


		# this data is all on one line, so we should just use scan and forget reparsing.
		if (wid)
            debug "we have a wid"

            # these are multi-line matches, so they are out of the scope of our
            # next
            if data =~ /id=\"ShortDescription\"\>(.*?)\<\/span\>/m
                debug "found short desc: [#{$1}]"
                shortdesc = $1
                shortdesc.gsub!(/\'+/, "\'")
                shortdesc.gsub!(/^\*/, '')
                @waypointHash[wid]['details'] = CGI.unescapeHTML(shortdesc)
            end

            if data =~ /id=\"LongDescription\"\>(.*?)\<\/span\><\/BLOCKQUOTE\>/m
                debug "found long desc"
                details =  cleanHTML(@waypointHash[wid]['details'] << "  " << $1)
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




    # cleans up HTML and makes it text-worthy.
    def cleanHTML(text)
        debug "pre-html-process: #{text}"
        # normalize, but work around the ruby 1.8.0 warnings.
        text.gsub!(/#{'\r\n'}/, ' ')
        text.gsub!(/#{'\r'}/, '')
        text.gsub!(/#{'\n'}/, '')

        debug "normalized: #{text}"
        # rip some tags out.
        text.gsub!(/\<\/li\>/i, '')
        text.gsub!(/\<\/p\>/i, '')
        text.gsub!(/<\/*i\>/i, '')
        text.gsub!(/<\/*body\>/i, '')
        text.gsub!(/<\/*option.*?\>/i, '')
        text.gsub!(/<\/*select.*?\>/i, '')
        text.gsub!(/<\/*span.*?\>/i, '')
        text.gsub!(/<\/*font.*?\>/i, '')
        text.gsub!(/<\/*ul\>/i, '')
        text.gsub!(/style=\".*?\"/i, '')

        debug "post-html-tags-removed: #{text}"

        # substitute
        text.gsub!(/\<p\>/i, "**")
        text.gsub!(/\<li\>/i, "\n * (o) ")
        text.gsub!(/<\/*b>/i, '')
        text.gsub!(/\<img.*?\>/i, '[img]')
        text.gsub!(/\<.*?\>/, ' *')
        debug "pre-combine-process: #{text}"

        # combine all the tags we nuked. These regexps
        # could probably be cleaned up pretty well.
        text.gsub!(/ +/, ' ')
        text.gsub!(/\* *\* *\*/, '**')
        text.gsub!(/\* *\* *\*/, '**')		# unnescesary
        text.gsub!(/\*\*\*/, '**')
        text.gsub!(/\* /, '*')
        debug "post-combine-process: #{text}"
        #text.gsub!(/[\x80-\xFF]/, "\'")		# high ascii
        #text.gsub!(/\&#\d+\;/, "\'")			# high ascii in entity format
        text.gsub!(/\&nbsp\;/, " ")			# unescapeHTML seems to ignore.
        text.gsub!(/\'+/, "\'")			# multiple apostrophes
        text.gsub!(/^\*/, '')			# lines that start with *

		# kill the last space, which makes the CSV output nicer.
		text.gsub!(/ $/, '')

        # convert things into plain text.
        text = CGI.unescapeHTML(text);
    end





    # PROOF OF CONCEPT CODE ONLY
    # this will be completely redone with a scientific approach and
    # moved into a ratings.rb file for GeoToad 3.7

    def determineRating(type, comment)

        debug"COMMENT: #{type} - #{comment}"

        rating = 0

        if type =~ /Didn\'t/
            rating = rating - 1
        end

        case comment
         when /best cache|awesome|breathtaking|coolest|neatest|great view|what a cool/i
            debug "extra: #{comment}"
            rating = rating + 0.95
         when /great cache|great place|another great|great.*time|great \w+ cache|excellent cache|very clever|great find|was great|excellent|beautiful|adventure|wow|be back|come back|nice drive|natural wonder|do it again/i
            debug "positive: #{comment}"
            rating = rating + 0.7
         when /neat|workout|great|wonderful|wow|very cool|clever|fun|glad|enjoyed|one of a kind|good one|perfect|excellent/
             rating = rating + 0.3
             debug "sorta pos: #{comment}"
         when /nightmare|try again|soggy|unfortunat|too easy|very easy|trash|broken|wasn\'t there|weren\'t allowed|trespassing|too much walking|ambiguous|gave up|give up/i
             debug "negative: #{comment}"
             rating = rating - 0.85

         when /briar|thorn|wrong|easy find|confused|wet/
             debug "sorta neg: #{comment}"
             rating = rating - 0.3
        end

        return rating
    end

end  # end class

