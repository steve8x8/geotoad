# $Id: search.rb,v 1.10 2002/08/05 03:38:51 strombt Exp $

require 'cgi'

class SearchCache < Common
	@@baseURL="http://www.geocaching.com/seek/nearest_cache.asp"
	#@@baseURL="http://home.profile.sh/index.html"

	def initialize
		@distance=15
		@waypointHash = Hash.new
	end

	def distance (dist)
		debug "setting distance to #{dist}"
		@distance = dist
	end

	# set the search mode. valid modes are 'zip', 'state_id', 'country_id', 'keyword',
	# coord
	def mode(mode, key)        
        # resolve North Carolina to 34. 
        keylookup=SearchCode.new(mode)
        @mode=keylookup.type
		@key=keylookup.lookup(key)
        if (! @key)
            puts "Bad search key for #{@mode} type: #{key}"
            return nil
        end
        
		# come up with a nice URL for the mode too.
		case @mode
			when 'coord'
				@url=@@baseURL + '?' + 'origin_lat=' + @lat + '&origin_long=' + @long
			else
				@url=@@baseURL + '?' + @mode + '=' + @key.to_s
			end

		if @distance
			@url = @url + '&dist=' + @distance.to_s
		end
		debug "URL for mode is #{@url}"
        return @url
	end

	# feed coordinates, which have two variables.
	def coordinates(lat, long)
		@lat = lat
		@long = long
		mode(coord, nil)
	end

	def baseURL
		@@baseURL
	end

	def URL
		@url
	end

	def waypoints
        debug "returning waypointHash (#{@waypointHash}) from search."
        @waypointHash.each_key { |wp|
            debug "returning #{wp}"
        }
		@waypointHash
	end

	def totalWaypoints
        debug "returning totalWaypoints from search (#{@totalWaypoints})"
		@totalWaypoints
	end

	def lastWaypoint
		@lastWaypoint
	end

	def returnedWaypoints
		@returnedWaypoints
	end

	def fetchNext
		debug "fetchNext called, last waypoint was #{@lastWaypoint} of #{@totalWaypoints}"

		if (! @totalWaypoints)
			return nil
		end
		nextWaypoint = @lastWaypoint

		if (@totalWaypoints > @lastWaypoint)
			debug "More waypoints needed! #{nextWaypoint} - first: #{@firstWaypoint}"
			newUrl = @url + '&start=' + @lastWaypoint.to_s
			fetch(newUrl)
		else
			return nil
		end
	end

	def fetchFirst
		fetch(@url)
	end

	def fetch(url)
		page = ShadowFetch.new(url)
        page.shadowExpiry=43200
        page.localExpiry=86400
            
		if (page.fetch)
			parseSearch(page.data)
		else
			debug "no page to parse!"
		end
	end

	def parseSearch(data)
		#debug "parsing search returns: #{data}"
		data.scan(/ (\d+) to (\d+) of (\d+) /) { |url|
			@firstWaypoint = $1.to_i
			@lastWaypoint = $2.to_i
			@totalWaypoints = $3.to_i
			@returnedWaypoints = @lastWaypoint - @firstWaypoint  + 1
		}

		#puts data

		#									1-type									2-cdate				3-distance (NO MORE)						4-name				5-creator			6-wid										# 7-state							# 8-mdate							# 9-diff		# 10-terrain										# 11-sid
		#<A HREF="/about/cache_types.asp" target="_blank"><IMG SRC='/images/cache_types/4.gif' alt='virtual cache'WIDTH=22 HEIGHT=30 BORDER=0></A></TD><TD VALIGN=TOP ALIGN=LEFT nowrap><font face='Verdana,Arial' size='2'>3/23/2002<br></td><td valign=top align=RIGHT width=28>&nbsp;</TD><TD VALIGN=TOP ALIGN=LEFT><font face='Verdana,Arial' size='2'><STRONG>&quot;Roger Ramjet&quot; by JoeyBob and #1 Son </STRONG>(GC4509)<STRONG><BR>(North Carolina) </strong><font size=1>last found 3/26/2002</font></td><td valign=top align=left><font face='Verdana,Arial' size='2'><strong>1/1</strong></font></TD><TD valign=top align=left><font face='Verdana,Arial' size='2'>[<A HREF='cache_details.asp?ID=17673'>details</A>]</FONT><BR></font></TD></TR><TR><TD COLSPAN=5>&nbsp;</TD></TR>
		# test.
		#data.scan(/alt=(.*)/) { |url|
		#	puts $1
		#}

        #alt='regular cache'WIDTH=22 HEIGHT=30 BORDER=0></A></TD><TD VALIGN=TOP ALIGN=LEFT nowrap><font face='Verdana,Arial' size='2'>2/17/2002<br>5.2mi N<BR>(8.5km)</td><td valign=top align=RIGHT width=28>&nbsp;</TD><TD VALIGN=TOP ALIGN=LEFT><font face='Verdana,Arial' size='2'><STRONG>&quot;Office Trek&quot; by Groves_Trekkers </STRONG>(GC3ABE)<STRONG><BR>(North Carolina) </strong><font size=1>last found 10/14/2002</font></td><td valign=top align=left><font face='Verdana,Arial' size='2'><strong>2/2.5</strong></font></TD><TD valign=top align=left><font face='Verdana,Arial' size='2'>[<A HREF='cache_details.aspx?ID=15038'>details</A>]</FONT><BR></font></TD></TR><TR><TD COLSPAN=5>&nbsp;</TD></TR>
		data.scan(/alt=\'(.*?)\'W(.*?)\>([\d\/]+)\<br\>.*?&quot\;(.*?)\&quot\; by (.*?) \<.*?\((\w+)\)\<S.*?\>\((.*?)\)(.*?)ng\>([\d\.]+)\/([\d\.]+)\<.*?aspx\?ID=(\d+)/) { |url|
			wid = $6
			@waypointHash[wid] = Hash.new
			type = $1
            @waypointHash[wid]['type'] = 

            bugPossible=$2
			@waypointHash[wid]['cdate'] = $3
			# distance is only in zipcode/coord search. don't bother.
			#@waypointHash[wid]['distance'] = $3.to_f
			name = CGI.unescape($4);
			@waypointHash[wid]['creator'] = CGI.unescape($5)
			@waypointHash[wid]['state'] = $7
            
			# this needs to be processed further.
            mdate = $8

            
			@waypointHash[wid]['difficulty'] = $9.to_f
			@waypointHash[wid]['terrain'] = $10.to_f
			@waypointHash[wid]['sid'] = $11.to_i
			@waypointHash[wid]['visitors'] = []
            
            # and this is lame.
            mdate =~ /last found ([\d\/]+)/
            if ($1) 
                @waypointHash[wid]['mdate'] = $1
            else
                @waypointHash[wid]['mdate'] = nil
                debug "#{wid} has never been found! (#{mdate})"
            end
            
            @waypointHash[wid]['name'] = name.gsub("[\x80-\xFF]", "\'") 
            
            type.gsub!('\s*cache', '')
            @waypointHash[wid]['type'] = type
            
            
            if (bugPossible =~ /icon_bug/)
                debug "Travel bug found in #{wid}"
                @waypointHash[wid]['travelbug']='Travel Bug!';
            end
                
			debug "Search found: #{wid}: #{@waypointHash[wid]['name']}"
		}
	end
end

