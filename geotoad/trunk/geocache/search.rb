# $Id: search.rb,v 1.10 2002/08/05 03:38:51 strombt Exp $

require 'cgi'

class SearchCache < Common
	@@baseURL="http://www.geocaching.com/seek/nearest.aspx"
	#@@baseURL="http://home.profile.sh/index.html"

	def initialize
		@distance=15
		@waypointHash = Hash.new
        @fetchID=0
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

        # This is a ridiculous hack. We tack this onto the URL as cid (cache id), so we
        # can store this independantly in our local and remote webcache. We also do the same
        # with resultsPager, so we know what "page" we are on.. in theory.
        @fetchID = @fetchID + 1

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
            newUrl = @url + "&gtid=#{@resultsPager}&cid=#{@fetchID}"
            debug "More waypoints needed! #{nextWaypoint} - first: #{@firstWaypoint} (gtid=#{@resultsPager}, cid=#{@fetchID})"
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

                when /WptTypes.*alt=\"(.*?)\" border=0/
                    @cache['type']=$1
                    @cache['mdays']=-1
                    @cache['type'].gsub!(/\s*cache.*/, '')
                    @cache['type'].gsub!('-', '')
                    debug "type=#{@cache['type']}"

                when /nowrap\>\(([\d\.]+)\/([\d\.]+)\)\<\/td\>/
                    @cache['difficulty']=$1.to_f
                    @cache['terrain']=$2.to_f
                    debug "cacheDiff=#{@cache['difficulty']} terr=#{@cache['terrain']}"

                when /<td valign=\"top\" align=\"left\"\>(\d+) (\w+) \'(\d+)\<\/td\>/
                    cday = $1
                    cmonth = $2
                    cyear = $3

                    @cache['cdate']=cday + cmonth.downcase + cyear
                    # I hate people who use 2 digit dates.
                    cyearProper = "20" + cyear
                    t = Time.new
                    ctimestamp = Time.local(cyearProper.to_i,cmonth,cday.to_i,00,00,0)
                    cage = t - ctimestamp
                    @cache['cdays'] = (cage / 3600 / 24).to_i

                    debug "cacheDate=#{@cache['cdate']} cdays=#{@cache['cdays']}"

                # <td valign="top" align="left">0.3mi&nbsp;<br>SE</td>

                when /\>([\d\.]+)mi.*?\>([NWSE]+)\</
                    @cache['distance']=$1.to_f
                    @cache['direction'] = $2
                    debug "cacheDistance=#{@cache['distance']} dir=#{@cache['direction']}"

                when /cache_details.aspx\?guid=(.*?)\">(.*?)\<\/a\>/
                    @cache['sid']=$1
                    name=$2.dup
                    name.gsub!(/ +$/, '')
                    if name =~ /\<strike\>(.*?)\<\/strike\>/
                        @cache['disabled']=1
                        name=$1.dup
                    end
                    @cache['name']=CGI.unescape(name).gsub(/[\x80-\xFF]/, "\'")
                    debug "sid=#{@cache['sid']} name=#{@cache['name']} (disabled=#{@cache['disabled']})"

                when /\bby (.*)/
                    creator = $1.dup
                    @cache['creator']=CGI.unescape(creator).gsub(/[\x80-\xFF]/, "\'").chop!
                    debug "creator=#{@cache['creator']}"
                when /\((GC\w+)\)/
                    wid=$1.dup
                    debug "wid=#{wid}"

                    # We have a WID! Lets begin
                when /icon_bug/
                    @cache['travelbug']='Travel Bug!'

                when /\<td valign=\"top\" align=\"left\"\>Today\</
                    @cache['mdays']=0

                when /\<td valign=\"top\" align=\"left\"\>Yesterday\</
                    @cache['mdays']=1

                when /\<td valign=\"top\" align=\"left\"\>(\d+) days ago\</
                    @cache['mdays']=$1.to_i
                    debug "mdays=#{@cache['mdays']}"

                 when /\<td valign=\"top\" align=\"left\"\>(\d+) months ago\</
                    # not exact, but close.
                    @cache['mdays']=$1.to_i * 30
                    debug "mdays=#{@cache['mdays']} (converted from months)"

                 # not sure if this case actually exists.
                 when /\<td valign=\"top\" align=\"left\"\>(\d+) years ago\</
                    # not exact, but close.
                    @cache['mdays']=$1.to_i * 365
                    debug "mdays=#{@cache['mdays']} (converted from years)"

                 when / ago/
                     debug "missing ago line: #{line}"

                # There is no good end of record marker, sadly.
                when /\<hr noshade width=\"100%\" size=\"1\">/
                    if (wid)
                        @waypointHash[wid] = @cache.dup
                        @waypointHash[wid]['visitors'] = []
                        if (@cache['mdays'] > -1)
                            t = Time.now
                            t2 = t - (@cache['mdays'] * 3600 * 24)
                            @waypointHash[wid]['mdate'] = t2.strftime("%d%b%y")
                            debug "mdays = #{@cache['mdays']} mdate=#{@waypointHash[wid]['mdate']}"
                        end

                        debug "*SCORE* Search found: #{wid}: #{@waypointHash[wid]['name']} (#{@waypointHash[wid]['difficulty']} / #{@waypointHash[wid]['terrain']})"
                        @returnedWaypoints = @returnedWaypoints + 1
                        @cache.clear
                    end

                when /^\<input type=\"hidden\" name=\"(.*?)\" value=\"(.*?)\" \/\>/
                    debug "found hidden post variable: #{$1}"
                    @postVars[$1]=$2
                when /\<form name=\"Form1\" method=\"post\" action=\"(.*?)\"/
                    @postURL='http://www.geocaching.com/seek/' + $1
                    @postURL.gsub!('&amp;', '&')
                    debug "post URL is #{@postURL}"

            end # end case
		} # end loop
	end #end parsecache
end # end class

