# $Id: search.rb,v 1.10 2002/08/05 03:38:51 strombt Exp $

require 'cgi'

class SearchCache < Common
	@@baseURL="http://www.geocaching.com/seek/nearest.aspx"
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
        wid=nil
        @cache = Hash.new

        data.each { |line|
            #debug "### #{line}"

            case line 
                when /Total Records: \<b\>(\d+)\<\/b\> - Page: \<b\>(\d+)\<\/b\> of \<b\>(\d+)\<\/b\>/
                    @totalWaypoints = $1.to_i
                    currentPage = $2.to_i
                    totalPages = $3.to_i
                    # emulation of old page behaviour (pre-Jun 2003). May not be required anymore.
                    debug "current page is #{currentPage} of #{totalPages}"
                    @firstWaypoint = (currentPage * 25) - 25  # 1st on the page
                    @lastWaypoint = (currentPage * 25)        # last on the page
                    if (lastWaypoint > @totalWaypoints)
                        @lastWaypoint = @totalWaypoints
                    end

                    @returnedWaypoints = @lastWaypoint - @firstWaypoint + 1
                    debug "Search has returned #{@returnWaypoints}"
                    
                when /WptTypes.*alt=\"(.*?)\" border=0 width=22 height=30/
                   
                    @cache['type']=$1
                    @cache['mdate']=nil
                    @cache['type'].gsub!('\s*cache.*', '')
                    @cache['type'].gsub!('-', '')
                    debug "type=#{@cache['type']}"
                    
                when /nowrap\>\((\d+)\/(\d+)\)\<\/td\>/
                    @cache['difficulty']=$1.to_f
                    @cache['terrain']=$2.to_f
                    debug "cacheDiff=#{@cache['difficulty']} terr=#{@cache['terrain']}"
                    
                when /align=\"left\">([\d\/]+)\<\/td\>/
                    @cache['cdate']=$1
                    debug "cacheDate=#{@cache['cdate']}"
                    
                when /align=\"left\">([\d\.]+)mi [NSWE]+\<br\>/
                    @cache['distance']=$1.to_f
                    debug "cacheDistance=#{@cache['distance']}"
                    
                when /cache_details.aspx\?guid=(.*?)\">(.*?)\<\/a\>/
                    @cache['sid']=$1
                    name=$2
                    if name =~ /\<strike\>(.*?)\<\/strike\>/
                        @cache['disabled']=1
                        name=$1
                    end
                    @cache['name']=CGI.unescape(name).gsub("[\x80-\xFF]", "\'") 
                    debug "sid=#{@cache['sid']} name=#{@cache['name']} (disabled=#{@cache['disabled']})"
                    
                when /\bby (.*)/
                    @cache['creator']=CGI.unescape($1)
                    debug "creator=#{@cache['creator']}"
                when /\((GC\w+)\)/
                    wid=$1
                    debug "wid=#{wid}"
                    
                    # We have a WID! Lets begin
                when /icon_bug/
                    @cache['travelbug']='Travel Bug!'
                    
                when /\<td valign=\"top\" align=\"left\"\>(\d+) days ago\<br\>/
                    @cache['mdate']=$1.to_i
                    debug "mdate=#{@cache['mdate']}"
                    
                # There is no good end of record marker, sadly.
                when /\<hr noshade width=\"100%\" size=\"1\">/
                    if (wid)
                        @waypointHash[wid] = @cache.dup
                        @waypointHash[wid]['visitors'] = []
                        debug "Search found: #{wid}: #{@waypointHash[wid]['name']} (sid=#{@waypointHash[wid]['sid']})"
                        @cache.clear
                    end
            end # end case
		} # end loop
	end #end parsecache
end # end class

