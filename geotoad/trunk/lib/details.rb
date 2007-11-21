# $Id$
require 'lib/bishop'
require 'time'

class CacheDetails
    attr_writer :useShadow, :cookie
    
    include Common
    include Display
    include Bishop
    
    # This now uses the printable version of the cache data. For now, we get the last 10
    # logs to a cache.
    @@baseURL="http://www.geocaching.com/seek/cache_details.aspx?pf=y&log=y&numlogs=5&decrypt="
    
    def initialize(data)
        @waypointHash = data
        @useShadow=1
        
        # we don't need to do this every cache! very inefficient.
        dataFile="fun_scores.dat"
        dataDirs=[ File.dirname(__FILE__) + "/../data", "../../data", "../data", "data", 
            File.dirname($0) + "/data", File.dirname($0) + "/../data", findConfigDir ]
            
        dataDirs.each do |dir|
            debug "checking #{dir} for #{dataFile}"
            if File.exists?(dir + "/" + dataFile)
                @funfile=dir + "/" + dataFile
                debug "found #{dir}/#{dataFile}"
            end
        end
                 
        if @funfile
            @@bayes = Bishop::Bayes.new
            if ! @@bayes.load(@funfile)
                displayMessage "Reading Bayesian data for FunFactor scores from {#@funfile}"
                @@funfactor=nil
            else
                debug "Loaded #{@funfile}"
                @@funfactor=1
            end
        else
            @@bayes=nil
            displayWarning "Could not find data/fun_scores.dat, FunFactor scores disabled"
        end
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
        if (@cookie)
            page.cookie=@cookie
        end
        
        page.fetch
        if (page.data)
            success = parseCache(page.data)
        else
            debug "No data found, not attempting to parse the entry at #{url}"
        end
        
        # We try to download the page one more time.
        if not success
          debug "Trying to download #{url} again."
          page.invalidate()
          page.fetch()
          success = parseCache(page.data)
        end
        
        if success
            return success
        else
            displayWarning "Could not parse #{url} (tried twice)"
            return nil
        end
    end
    
    def calculateFun(total, comments)
        # if no comments, it must be at least somewhat interesting!
        if comments == 0
            return 3.0
        end
    
        score=total / comments
        
        # a grade of >28 is considered awesome
        # a grade of <-20 is considered pretty bad
        debug "total=#{total} comments=#{comments} score=#{score}"        
        grade=((score + 25) / 5.3).round.to_f / 2
        if grade > 5.0
            grade=5.0
        elsif grade < 0.0
            grade=0.0
        end
        debug "calculateFun: score=#{score} grade=#{grade}"        
        return grade
    end
        
    def parseCache(data)
        # find the geocaching waypoint id.
        wid = nil
        
        data.each { |line|
            # this matches the <title> on the printable pages. Some pages have ) and some don't.
            if line =~  /^\s+\((GC[A-Z0-9]+)\)/
                # only do it if the wid hasn't been found yet, sometimes pages mention wid's of other caches.
                if (! wid)
                    wid = $1
                    debug "wid is #{wid}"
                    
                    # We give this a predefined value, because some caches have no details!
                    @waypointHash[wid]['shortdesc'] = ''
                    @waypointHash[wid]['longdesc'] = ''
                    
                    # Set what URL we used as our details source. We do not use baseURL because
                    # some GPX parsers freak if there is a & in this URL.
                    @waypointHash[wid]['url'] = "http://www.geocaching.com/seek/cache_details.aspx?wp=" + wid
                end
            end
            
            
            # DUPLICATE OF WHAT SEARCH.RB HAS! Only used for failures and or wid searches.
            # May make in the future have it decide which source is newest: search or details.
            if line =~ /\<span id=\"CacheName\"\>(.*?)\<\/span\>/
                if (! wid)
                    debug "Invalid cache, title is: #{$1}"
                elsif (! @waypointHash[wid]['name'])
                    @waypointHash[wid]['name'] = $1
                    debug "name was not set, now set to #{$1}"
                end
            end
            
            if line =~ /with an account to view/
              displayWarning "Oops, we are not actually logged in!"
              return 'login-required'
            end
            
            # DUPLICATE OF WHAT SEARCH.RB HAS! Only used for failures and or wid searches.
            # May make in the future have it decide which source is newest: search or details.
            if line =~ /\<br\>by (.*?) \[\<A HREF/
                if (! @waypointHash[wid]['creator'])
                    @waypointHash[wid]['creator'] = $1
                    debug "creator was not set, now set to #{$1}"
                    
                end
            end
                        
            # Regexp rewritten by Scott Brynen for Canadian compatibility
            if line =~ /getmap\.aspx\?lat=([\d\.-]+)\&lon=([\d\.-]+)/
                @waypointHash[wid]['latdata'] = $1
                @waypointHash[wid]['londata'] = $2
                debug "got digital lat/lon: #{$1} #{$2}"
            end
            
            if line =~ /LatLon/
                debug "LatLon: #{line}"
            end
            
            # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
            if line =~ /id=\"LatLon\".*\>.*?([NWSE]) (\d+).*? ([\d\.]+) ([NWSE]) (\d+).*? ([\d\.]+)\</
                @waypointHash[wid]['latwritten'] = $1 + $2 + ' ' + $3
                @waypointHash[wid]['lonwritten'] = $4 + $5 + ' ' + $6
                @waypointHash[wid]['latdata'] = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
                @waypointHash[wid]['londata'] = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
                debug "got written lat/lon"
            end
            
            if line =~ /viewable to subscribers only/
              return 'subscriber-only'
            end
            
            # why a geocache is closed. It seems to always be the same.
            if line =~ /\<span id=\"ErrorText\".*?>(.*?)\<\/span\>/
                warning = $1
                warning.gsub!(/\<.*?\>/, '')
                debug "got a warning: #{warning}"
                if (wid)
                    @waypointHash[wid]['warning'] = warning.dup
                end
            end
            
            # encrypted hint
            if line =~ /\<span id=\"Hints\".*?\>(.*?)\<\/span\>/m
                hint = $1.dup
                hint.gsub!(/\<.*?\>/, '')
                @waypointHash[wid]['hint'] = hint
                debug "got hint: #{hint}"
            end
            
            if line =~ /\<span id=\"CacheLogs\"\>/
                debug "inspecting comments"
                cnum = 0
                funTotal = 0.0
                fnum = 0
                
                # icon_smile.gif' align='absmiddle'>&nbsp;November 24, 2005 by <A NAME="11547243" style='text-decoration: underline;'><A HREF="../profile/?guid=43af89b2-3843-4ac6-85dd-74b489332ddf" 
                # style='text-decoration: underline;'>TKG</A></strong> (334 found)<br>#316 L! and B.  Finally got this one - took two tries.  My gps zero is about 50 feet east of actual cache.  Took: tb and 2 $1 bills which will become WheresGeorge.com bills.  Left: tb and truck.  Lots of MP3s still here to trade.  Happy Thanksgiving 2005!  Thanks for the cache.  <p>[This entry was edited by TKG on Friday, November 25, 2005 at 4:14:42 AM.]</font>
                line.scan(/icon_(\w+)\.gif.*?\&nbsp\;.*?([\w, ]+) by \<A NAME=\"(\d+)\".*?HREF.*?\>(.*?)\<.*?\<br\>(.*?)\<\/font\>/) { |icon, date, id, name, comment|
                    comment.gsub!(/\<.*?\>/, ' ')
                    type = 'unknown'
                    nograde=nil
                    
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
                        nograde=1
                    when 'camera'
                        type = 'Webcam Photo Taken'
                    when 'disabled'
                        type = 'Cache Disabled!'
                        nograde=1
                    else
                        type = 'Other'
                        nograde=1
                    end
                    
                    debug "comment [#{cnum}] is '#{type}' by #{name} on #{date}: #{comment}"
                    date = Time.parse(date)                    
                    @waypointHash[wid]["comment#{cnum}Type"] = type.dup
                    @waypointHash[wid]["comment#{cnum}Date"] = date.strftime("%Y-%m-%dT%H:00:00.0000000-07:00")
                    @waypointHash[wid]["comment#{cnum}ID"] = id.dup
                    @waypointHash[wid]["comment#{cnum}Icon"] = icon.dup
                    @waypointHash[wid]["comment#{cnum}Name"] = name.dup
                    @waypointHash[wid]["comment#{cnum}Comment"] = comment.dup
                    
                    if (nograde)
                        debug "not grading comment due to type #{icon}"
                    elsif (! @@bayes)
                        funTotal=1
                        fnum=1
                    else
                        guess=@@bayes.guess(comment)
                        if (guess[0] && guess[1])
                            fun = (guess[1][1] - guess[0][1]) * 100
                            if fun > 28.0
                                fun=28.0
                            end
                        else
                            debug "could not determine fun factor for comment: #{comment}"
                            fun=0
                        end
                        funTotal=funTotal + fun
                        fnum=fnum+1
                    end
                    debug "COMMENT #{cnum}: i=#{icon} d=#{date} id=#{id} n=#{name} c=#{comment} fun=#{fun}"
                    cnum = cnum + 1
                }   # no more comments
                
                @waypointHash[wid]['funfactor']=calculateFun(funTotal, fnum)
            end
            
        }
        
        
        # this data is all on one line, so we should just use scan and forget reparsing.
        if (wid)
            debug "we have a wid"
            
            # these are multi-line matches, so they are out of the scope of our
            # next
            if data =~ /id=\"ShortDescription\"\>(.*?)\<\/span\>/m
                shortdesc = $1
                debug "found short desc: [#{shortdesc}]"
                @waypointHash[wid]['shortdesc'] = cleanHTML(shortdesc)
            end
            
            if data =~ /\<span id=\"LongDescription\"\>(.*?)\<\/span\>/m
                longdesc = $1
                debug "got long desc [#{longdesc}]"
                @waypointHash[wid]['longdesc'] = cleanHTML(longdesc)
            end
            
            @waypointHash[wid]['details'] = @waypointHash[wid]['shortdesc'] + " ... " + @waypointHash[wid]['longdesc']
          
        end  # end wid check.
        
        # How valid is this cache?
        if wid && @waypointHash[wid]['latwritten']
            return 1
        else
            debug "parseCache returning as nil because wid #{wid} has no coordinates (and the login works?)"
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
    
end  # end class
