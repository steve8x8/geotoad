# $Id$

require 'cgi'

class SearchCache
    include Common
    include Display
    
    @@baseURL="http://www.geocaching.com/seek/nearest.aspx"
    
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
    
    
    # set the search mode. valid modes are 'zip', 'state', 'country', 'keyword', coord, user
    def mode(mode, key)
        case mode
        when 'state'
            keylookup=SearchCode.new(mode)		# i.e. resolve North Carolina to 34.
            @mode=keylookup.type
            @key=keylookup.lookup(key)
            # nearly everything is in this form
            @url=@@baseURL + '?' + @mode + '=' + CGI.escape(@key.to_s)
            
        when 'country'
            keylookup=SearchCode.new(mode)		# i.e. resolve North Carolina to 34.
            @mode=keylookup.type
            @key=keylookup.lookup(key)
            # nearly everything is in this form
            @url=@@baseURL + '?' + @mode + '=' + CGI.escape(@key.to_s)
            
            # as of aug2003, geocaching.com has an in-between page for country
            # lookups to parse. Pretty silly and worthless, imho.
            ## CURRENTLY BROKEN - NEEDS HELP BADLY!!!! ##
            displayError "Country searches are currently broken. Please help fix!"
            return nil
            
            #debug 'fetching the country page'
            # add go button to the URL, just in case.
            #@url = @url + "&submit3=GO"
            #data = fetch(@url)
            #data.each { |line|
            #    if (line =~ /^\<input type=\"hidden\" name=\"(.*?)\" value=\"(.*?)\" \/\>/)
            #        debug "found hidden post variable: #{$1}"
            #        @postVars[$1]=$2
            #    end
            #}
            #debug "country page parsed"
            
        when 'coord'
            @mode = 'coordinate'
            @key = key
            # This regular expression should probably handle any kind of messed
            # up input the user could conjure. Thanks to Scott Brynen for help.
            
            #       N             48    °   08.152          E         011    ° 39.308 '
            re = /^([ns-]?)\s*([\d\.]+)\W*([\d\.]*)[\s,]+([ew-]?)\s*([\d\.]+)\W*([\d\.]+)/i
            #*(\d+)\W(\d+)\W*(\d+)$/i
            md = re.match(key)
            
            if ! md
                displayError "Bad format in #{key}! Try something like \"N56 44.392 E015 52.780\" instead"
                return nil
            end
            
            
            
            lat_dir = md[1]
            lat_h = md[2]
            lat_ms = md[3]
            
            long_dir = md[4]
            long_h = md[5]
            long_ms = md[6]
            
            lat_ns = 1
            long_ew = 1
            
            if lat_dir == 's' || lat_dir == 'S' || lat_dir == '-'
                lat_ns = -1
            end
            
            if long_dir == 'w' || long_dir == 'W' || long_dir == '-'
                long_ew = -1
            end
            
            
            displayMessage "Coordinate's have been parsed as latitude #{lat_dir} #{lat_h}'#{lat_ms}, longitude #{long_dir} #{long_h}'#{long_ms}"
            
            @url = @@baseURL + '?lat_ns=' + lat_ns.to_s + '&lat_h=' + lat_h + '&lat_mmss=' + (lat_ms==''?'0':lat_ms) + '&long_ew=' + long_ew.to_s + '&long_h=' + long_h + '&long_mmss=' + (long_ms==''?'0':long_ms)
            
            if @distance
                @url = @url + '&dist=' + @distance.to_s
            end
            
        when 'user'
            @mode = mode
            @key = key
            @url=@@baseURL + '?ul=' + CGI.escape(@key)  # I didn't see the point of adding a dummy lookup
            
        when 'keyword'
            @mode = mode
            @key = key
            @url=@@baseURL + '?key=' + CGI.escape(@key)  # I didn't see the point of adding a dummy lookup
            
        when 'zipcode'
            # nearly everything is in this form
            @mode = 'zip'
            @key = key
            
            @url=@@baseURL + '?' + @mode + '=' + CGI.escape(@key.to_s) + "&submit1=Submit"
            
            if (@key !~ /^[\w][\w ]+$/)
                displayError "Invalid zip code format: #{@key}"
                return nil
            end
            
            if @distance
                @url = @url + '&dist=' + @distance.to_s
            end
        when 'wid'
            # uhm.
            @mode = 'wid'
            @key = key
            
            @url = "http://www.geocaching.com/seek/cache_details.aspx?wp=#{@key}"
            
            if (@key !~ /^GC/)
                displayError "Waypoint ID's must start with GC"
                return nil
            end
            
        else
            displayWarning "Not sure what kind of search \"#{mode}\" is!"
        end
        
        
        debug "URL for mode #{mode} is #{@url}"
        return @url
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
    
    def waypointList
        @waypointHash.keys
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
    
    # This function used to be in the CLI but was moved in here by Mike Capito's
    # userlist patch. This loop downloads all the pages needed.
    def fetchSearchLoop
        # Wid's don't actually have a search loop, so we fake it.
        if (@mode == 'wid')
            fakeSearchLoop
            return
        end
        
        
        # fetches the first page in the search listing, so we can determine
        # how many search pages we need to download.
        fetchFirst
        
        if (totalWaypoints)
            progress = ProgressBar.new(1, totalPages, "#{@mode} query for #{@key}")
            
            # the loop that gets all of them.
            running = 1
            downloads = 0
            resultsPager = 5
            while(running)
                # short-circuit for lack of understanding.
                debug "(download while loop - #{currentPage} of #{totalPages})"
                
                if (totalPages > currentPage)
                    lastPage = currentPage
                    # I don't think this does anything.
                    page = ShadowFetch.new(@url)
                    running = fetchNext
                    src = page.src
                    # update it.
                    progress.updateText(currentPage, "from #{src}")
                    
                    if (currentPage <= lastPage)
                        displayError "Geocache Search Logic error. I was at page #{lastPage} before, why am I at #{currentPage} now?"
                        exit
                    end
                    
                    if (src == "remote")
                        # give the server a wee bit o' rest.
                        downloads = downloads + 1
                        # half the rest for this.
                        debug "sleeping"
                        sleep=$SLEEP*1.5
                        sleep(sleep)
                    end
                else
                    debug "We have already downloaded the waypoints needed, lets get out of here"
                    running = nil
                end # end totalPages if
            end # end while(running)
        else
            displayWarning "No waypoints found in #{@mode}=#{@key} search. Possible error fetching #{@url}"
        end
    end
    
    def fetch(url)
        page = ShadowFetch.new(url)
        if (@mode == "user")
            page.localExpiry=43200
        else
            page.localExpiry=72000
        end
        
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
                # emulation of old page behaviour (pre-Jun 2003). May not be required anymore.
                debug "current page is #{currentPage} of #{totalPages}"
                @firstWaypoint = (currentPage * 20) - 20  # 1st on the page
                @lastWaypoint = (currentPage * 20)        # last on the page
                if (@lastWaypoint > @totalWaypoints)
                    @lastWaypoint = @totalWaypoints
                end
                
            when /WptTypes.*alt=\"(.*?)\" title/
                @cache['type']=$1
                @cache['mdays']=-1
                @cache['type'].gsub!(/\s*cache.*/, '')
                @cache['type'].gsub!(/\-/, '')
                debug "type=#{@cache['type']}"
                
            when /nowrap\>\(([-\d\.]+)\/([-\d\.]+)\)\<br/
                @cache['difficulty']=$1.to_f
                @cache['terrain']=$2.to_f
                debug "cacheDiff=#{@cache['difficulty']} terr=#{@cache['terrain']}"
                
            when /<td valign=\"top\" align=\"left\"\>(\d+) (\w+) \'(\d+) *\<[\/I]/
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
                
            when /([NWSE]+)\<br \/\>([\d\.]+)mi</
                @cache['distance']=$2.to_f
                @cache['direction'] = $1
                debug "cacheDistance=#{@cache['distance']} dir=#{@cache['direction']}"
                
            when /alt=\"Size: (.*)\"/
                @cache['size'] = $1
                debug "cache size is #{$1}"
                
            when /cache_details.aspx\?guid=(.*?)\">(.*?)\<\/a\>/
                debug "cache line: #{line}"
                @cache['sid']=$1
                if $2
                    name=$2.dup
                else
                    name='not_parsed'
                end
                name.gsub!(/ +$/, '')
                if name =~ /\<strike\>\<font color=\"red\"\>(.*?)\<\/font\>\<\/strike\>/
                    @cache['disabled']=1
                    name=$1.dup
                    debug "#{name} appears to be disabled"
                end
                
                # re-enabled to fix &quot; -- what else will we be messing up?
                name = CGI.unescapeHTML(name);
                @cache['name']=name
                debug "sid=#{@cache['sid']} name=#{@cache['name']} (disabled=#{@cache['disabled']})"
                
            when /\bby (.*)/
                creator = $1.dup
                if (creator)
                    creator =  CGI.unescapeHTML(creator);
                    creator.gsub!(/\s+$/, '')
                end
                @cache['creator']=creator
                #creator.gsub(/[\x80-\xFF]/, '?').chop!
                debug "creator=#{@cache['creator']}"
                
            when /\((GC\w+)\)/
                wid=$1.dup
                debug "wid=#{wid}"
                
                # We have a WID! Lets begin
            when /icon_bug/
                @cache['travelbug']='Travel Bug!'
                
            when /Member-only/
                debug "Found members only cache. Marking"
                @cache['membersonly'] = 1
                
            when /\<td valign=\"top\" align=\"left\"\>Today\**\</
                @cache['mdays']=0
                
            when /\<td valign=\"top\" align=\"left\"\>Yesterday\**\</
                @cache['mdays']=1
                
            when /\<td valign=\"top\" align=\"left\"\>(\d+) days ago\**\</
                @cache['mdays']=$1.to_i
                debug "mdays=#{@cache['mdays']}"
                
                # <td valign="top" align="left">24 Apr 03<br>
            when /<td valign=\"top\" align=\"left\"\>(\d+) (\w+) (\d+)\<br\>/
                mday = $1
                mmonth = $2
                myear = $3
                
                myearProper = "20" + myear
                debug "mod time is #{mday}  #{mmonth} #{myearProper}"
                t = Time.new
                mtimestamp = Time.local(myearProper.to_i,mmonth,mday.to_i,00,00,0)
                mage = t - mtimestamp
                @cache['mdays'] = (mage / 3600 / 24).to_i
                
                debug "mdays=#{@cache['mdays']}"
                
            when / ago/
                debug "missing ago line: #{line}"
                
                # There is no good end of record marker, sadly.
            when /^\t\t\<\/tr\>\<tr\>/
                if (wid)
                    @waypointHash[wid] = @cache.dup
                    @waypointHash[wid]['visitors'] = []
                    
                    # if our search is for caches that have been done by a particular user,
                    # we may as well add that user to the hash!
                    if @mode == "users"
                        @waypointHash[wid]['visitors'].push(@key.downcase)
                    end
                    
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
    
    # This is for wid searches.
    def fakeSearchLoop
        wid = @key
        debug "Faking a search loop for wid search for #{wid}"
        @waypointHash[wid] = Hash.new
        
        # I don't like that we need to set it, but otherwise we get an error later on
        # in details.rb
        @waypointHash[wid]['visitors'] = []
        
        # temporary, until I write some details sniffers for these. It's ugly cause it's
        # not just a number in details, it's a *** 1/2 diagram.
        @waypointHash[wid]['terrain'] = 0
        @waypointHash[wid]['difficulty'] = 0
        @waypointHash[wid]['mdays'] = 1
        @returnedWaypoints = 1
    end
    
end # end class
