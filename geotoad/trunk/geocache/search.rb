# $Id: search.rb,v 1.10 2002/08/05 03:38:51 strombt Exp $

require 'cgi'

class SearchCache < Common
	@@baseURL="http://www.geocaching.com/seek/nearest.aspx"
	#@@baseURL="http://home.profile.sh/index.html"

	def initialize
		@distance=15
		@waypointHash = Hash.new
        @resultsPager=nil
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
        debug "returning totalWaypoints available from search: #{@totalWaypoints}"
		@totalWaypoints
	end

	def lastWaypoint
        debug "returning last waypoint on this page: #{@lastWaypoint}"
		@lastWaypoint
	end

	def returnedWaypoints
        debug "returning number of returned waypoints: #{@returnedWaypoints}"
		@returnedWaypoints
	end

    def currentPage
        debug "returning the current page: #{@currentPage}"
        @currentPage
    end

    def totalPages
        debug "returning the total pages: #{@totalPages}"
        @totalPages
    end

	def fetchNext
		debug "fetchNext called, last waypoint was #{@lastWaypoint} of #{@totalWaypoints}"

		if (! @totalWaypoints)
			return nil
		end
		nextWaypoint = @lastWaypoint

        # I don't know why it starts as 5, but it does. It resets at 14 for the next page.
        if ((! @resultsPager))
            @resultsPager=5
        else
            @resultsPager = @resultsPager + 1
        end

        if (@resultsPager > 14)
            debug "reset the resultsPager from #{@resultsPager} to 5"
            @resultsPager=5
        end

		if (@totalWaypoints > @lastWaypoint)

			#newUrl = @url + '&start=' + @lastWaypoint.to_s
            newUrl = @url + "&gtid=#{@resultsPager}"
            debug "More waypoints needed! #{nextWaypoint} - first: #{@firstWaypoint} (gtid=#{@resultsPager})"
            @postVars['__EVENTTARGET']="ResultsPager:_ctl#{@resultsPager}"
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
        page.shadowExpiry=60000
        page.localExpiry=43200
        if (@postVars)
            page.postVars=@postVars
        end

		if (page.fetch)
			parseSearch(page.data)
		else
			debug "no page to parse!"
		end
	end

    # for the eventstate thing
    def postVars
        @postVars
    end

    def postURL
        @postURL
    end

	def parseSearch(data)
        wid=nil
        @cache = Hash.new
        @postVars = Hash.new
        @returnedWaypoints = 0

        data.each { |line|
            #debug "### #{line}"
            case line
                when /Total Records: \<b\>(\d+)\<\/b\> - Page: \<b\>(\d+)\<\/b\> of \<b\>(\d+)\<\/b\>/
                    @totalWaypoints = $1.to_i
                    @currentPage = $2.to_i
                    @totalPages = $3.to_i
                    #puts line
                    # emulation of old page behaviour (pre-Jun 2003). May not be required anymore.
                    debug "current page is #{currentPage} of #{totalPages}"
                    @firstWaypoint = (currentPage * 20) - 20  # 1st on the page
                    @lastWaypoint = (currentPage * 20)        # last on the page
                    if (@lastWaypoint > @totalWaypoints)
                        @lastWaypoint = @totalWaypoints
                    end

                when /WptTypes.*alt=\"(.*?)\" border=0 width=22 height=30/

                    @cache['type']=$1
                    @cache['mdate']=nil
                    @cache['type'].gsub!('\s*cache.*', '')
                    @cache['type'].gsub!('-', '')
                    debug "type=#{@cache['type']}"

                when /nowrap\>\(([\d\.]+)\/([\d\.]+)\)\<\/td\>/
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

                when /\<td valign=\"top\" align=\"left\"\>(\d+) days ago\</
                    @cache['mdate']=$1.to_i
                    debug "mdate=#{@cache['mdate']}"

                 when /\<td valign=\"top\" align=\"left\"\>(\d+) months ago\</
                    # not exact, but close.
                    @cache['mdate']=$1.to_i * 30
                    debug "mdate=#{@cache['mdate']} (converted from months)"

                 # not sure if this case actually exists.
                 when /\<td valign=\"top\" align=\"left\"\>(\d+) years ago\</
                    # not exact, but close.
                    @cache['mdate']=$1.to_i * 365
                    debug "mdate=#{@cache['mdate']} (converted from years)"

                 when / ago/
                     debug "missing ago line: #{line}"

                # There is no good end of record marker, sadly.
                when /\<hr noshade width=\"100%\" size=\"1\">/
                    if (wid)
                        @waypointHash[wid] = @cache.dup
                        @waypointHash[wid]['visitors'] = []
                        debug "*SCORE* Search found: #{wid}: #{@waypointHash[wid]['name']} (#{@waypointHash[wid]['difficulty']} / #{@waypointHash[wid]['terrain']})"
                        @returnedWaypoints = @returnedWaypoints + 1
                        @cache.clear
                    end

                when /^\<input type=\"hidden\" name=\"(.*?)\" value=\"(.*?)\" \/\>/
                    debug "found hidden post variable: #{$1}"
                    @postVars[$1]=$2
                when /\<form name=\"Form1\" method=\"post\" action=\"(.*?)\"/
                    @postURL='http://www.geocaching.com/seek/' + $1
                    @postURL.gsub!("\&amp;", "\&")
                    debug "post URL is #{@postURL}"

            end # end case
		} # end loop
	end #end parsecache
end # end class

