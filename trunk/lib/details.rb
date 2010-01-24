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
      if success == 'login-required'
        page.invalidate()
      end
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
        
    data.split("\n").each { |line|
      # GC1N069 Cacti in the Woods (Traditional Cache) in North Carolina, United States created by eminwf
      if line =~  /^\s+(GC[A-Z0-9]+) (.*?) \((.*?)\) in.*created by (.*)/
        wid = $1
        name = $2
        type = $3
        creator = $4
        debug "wid = #{wid} name=#{name} type=#{type} creator=#{creator}"
        @waypointHash[wid]['fulltype']=type
        @waypointHash[wid]['type']=type.downcase.gsub(/\s.*/i, '').gsub!(/\-/, '')
        @waypointHash[wid]['name'] = name
        @waypointHash[wid]['creator'] = creator
        @waypointHash[wid]['shortdesc'] = ''
        @waypointHash[wid]['longdesc'] = ''
        @waypointHash[wid]['details'] = ''

        # Set what URL we used as our details source. We do not use baseURL because
        # some GPX parsers freak if there is a & in this URL.
        @waypointHash[wid]['url'] = "http://www.geocaching.com/seek/cache_details.aspx?wp=" + wid
      end   
        
      # <strong>Difficulty:</strong> <span id="ctl00_ContentBody_Difficulty"><img src="http://www.geocaching.com/images/stars/stars2.gif" alt="2 out of 5" />
      if line =~ /Difficulty:.*?([-\d\.]+) out of 5/
        debug "difficulty: #{$1}"
        @waypointHash[wid]['difficulty']=$1.to_f
      end

      # strong>Terrain:</strong> <span id="ctl00_ContentBody_Terrain"><img src="http://www.geocaching.com/images/stars/stars2.gif" alt="2 out of 5" />
      if line =~ /Terrain:.*?([-\d\.]+) out of 5/
        debug "terrain: #{$1}"
        @waypointHash[wid]['terrain']=$1.to_f
      end

      # DateHidden">2/22/2009</span>
      if line =~ /DateHidden\">([\w\/]+)\</
        if $1 != 'N/A'
          @waypointHash[wid]['ctime'] = parseDate($1)
          @waypointHash[wid]['cdays'] = daysAgo(@waypointHash[wid]['ctime'])
          debug "ctime=#{@waypointHash[wid]['ctime']} cdays=#{@waypointHash[wid]['cdays']}"
        end
      end
            
      if line =~ /with an account to view/
        displayWarning "Oops, we are not actually logged in!"
        return 'login-required'
      end
 
      # href="/wpt/?lat=35.933717&amp;lon=-78.487483&amp;detail=1" 
      if line =~ /\?lat=([\d\.-]+)\&lon=([\d\.-]+)/
        @waypointHash[wid]['latdata'] = $1
        @waypointHash[wid]['londata'] = $2
        debug "got digital lat/lon: #{$1} #{$2}"
      end
            

      # span id="ctl00_ContentBody_Location">In North Carolina, United States <small>
      if line =~ /Location\"\>In ([^,<]+)\, ([^<]+)/
        @waypointHash[wid]['state']=$1
        @waypointHash[wid]['country']=$2
        debug "found state: #{$1} country: #{$2}"
        # <span id="Location">In Country</span></p>
      elsif line =~ /Location\"\>In ([^<]+)/
        @waypointHash[wid]['state']=nil
        @waypointHash[wid]['country']=$1
        debug "found country: #{$1}"
      end
      
      # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
      if line =~ /LatLon\".*\>.*?([NWSE]) (\d+).*? ([\d\.]+) ([NWSE]) (\d+).*? ([\d\.]+)\</
        @waypointHash[wid]['latwritten'] = $1 + $2 + ' ' + $3
        @waypointHash[wid]['lonwritten'] = $4 + $5 + ' ' + $6
        @waypointHash[wid]['latdata'] = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
        @waypointHash[wid]['londata'] = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
        debug "got written lat/lon"
      end
            
      # why a geocache is closed. It seems to always be the same.
      # <span id="ctl00_ContentBody_ErrorText"><p class="OldWarning"><strong>Cache Issues:</strong></p><ul class="OldWarning"><li>This cache is temporarily unavailable. Read the logs below to read the status for this cache.</li></ul></span>
      if line =~ /ErrorText\".*?>(.*?)\<\/span\>/
        warning = $1
        warning.gsub!(/\<.*?\>/, '')
        debug "got a warning: #{warning}"
        if (wid)
          @waypointHash[wid]['warning'] = warning.dup
        end
        if warning =~ /Premium Member/
          debug "This cache appears to be available to premium members only."
          return 'subscriber-only'
        end
      end
            
      # pan id="ctl00_ContentBody_Hints" class="displayMe">GuERR sbhe hfr gur onpx qbbe!!</span><span id="ctl00_ContentBody_decryptHint" class="hideMe">(Decrypted Hints)</span><
      if line =~ /class="displayMe"\>(.*?)\<\/span/
        hint = $1.dup
        hint.gsub!(/\<.*?\>/, '')
        @waypointHash[wid]['hint'] = hint
        debug "got hint: #{hint}"
      end
            
      
      if line =~ /CacheLogs\"\>/
        debug "inspecting comments"
        cnum = 0
        funTotal = 0.0
        fnum = 0

        line.gsub!(/\<p\>/, ' ')
        # <td class="Nothing"><strong><img src="http://www.geocaching.com/images/icons/icon_smile.gif" alt="" />&nbsp;December 8, 2009 by <a href="/profile/?guid=55c35fc8-b0e9-407f-b182-9d9aff86eca6" id="92528794">The Shire</a></strong> (2589 found)<br />I found this one today while out caching with GHAS.  TFTC!<br />
        line.scan(/icon_(\w+)\.gif.*?&nbsp;([\w, ]+) by \<a href.*?id=\"(\d+)".*?\>(.*?)\<\/a\>.*?<br \/\>(.*?)\</) { |icon, date, id, name, comment|
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
          comment.gsub!(/\<.*?\>/, ' ')
          date = Time.parse(date)
          if type == 'Found it' and not @waypointHash[wid]['mtime']:
            debug "Found successful comment, updating mtime to #{date}"
            @waypointHash[wid]['mtime'] = date
            @waypointHash[wid]['mdays'] = daysAgo(date)
          end
          @waypointHash[wid]["comment#{cnum}Type"] = type.dup
          @waypointHash[wid]["comment#{cnum}Date"] = date.strftime("%Y-%m-%dT%H:00:00.0000000-07:00")
          @waypointHash[wid]["comment#{cnum}ID"] = id.dup
          @waypointHash[wid]["comment#{cnum}Icon"] = icon.dup
          @waypointHash[wid]["comment#{cnum}Name"] = name.dup
          @waypointHash[wid]["comment#{cnum}Comment"] = cleanHTML(comment.dup)
                    
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
      if data =~ /id=\"ShortDescription\"\>(.*?)\<\/span\>\s\s\s\s/m
        shortdesc = $1
        debug "found short desc: [#{shortdesc}]"
        @waypointHash[wid]['shortdesc'] = cleanHTML(shortdesc)
      end
            
      if data =~ /id=\"LongDescription\"\>(.*?)<\/span\>\s\s\s\s/m
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
    text.gsub!(/[\x01-\x1F]/, '')      # low ascii
    text.gsub!(/\&nbsp\;/, " ")
    text.gsub!(/\'+/, "\'")			# multiple apostrophes
    text.gsub!(/^\*/, '')			# lines that start with *
        
    # kill the last space, which makes the CSV output nicer.
    text.gsub!(/ $/, '')
    return text
  end
    
end  # end class
