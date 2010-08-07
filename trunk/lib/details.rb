# $Id$
require 'lib/bishop'
require 'time'
require 'zlib'

class CacheDetails
  attr_writer :useShadow, :cookie

  include Common
  include Messages
  include Bishop

  # Use a printable template that shows the last 10 logs.
  @@baseURL="http://www.geocaching.com/seek/cdpf.aspx?lc=10"

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
      sleep(5)
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

    score=total.to_f / comments.to_f

    # a grade of >28 is considered awesome
    # a grade of <-20 is considered pretty bad
    debug "fun total=#{total} comments=#{comments} score=#{score}"
    grade=((score + 25) / 5.3).round.to_f / 2.0
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
      # <title id="pageTitle">(GC1145) Lake Crabtree computer software store by darylb</title> 
      if line =~ /\<title.*\((GC\w+)\) (.*?) by (.*?)\</
        wid = $1
        name = $2
        creator = $4
        debug "wid = #{wid} name=#{name} creator=#{creator}"
        @waypointHash[wid]['name'] = name
        @waypointHash[wid]['creator'] = creator
        # Calculate a semi-unique integer creator id, since we can no longer get it from this page.
        @waypointHash[wid]['creator_id'] = Zlib.crc32(creator)
        @waypointHash[wid]['shortdesc'] = ''
        @waypointHash[wid]['longdesc'] = ''
        @waypointHash[wid]['details'] = ''
        @waypointHash[wid]['funfactor'] = 0
        @waypointHash[wid]['url'] = "http://www.geocaching.com/seek/cache_details.aspx?wp=" + wid

        if not @waypointHash[wid]['mtime']
          @waypointHash[wid]['mdays'] = -1
          @waypointHash[wid]['mtime'] = Time.at(0)
        end
      end

      # <h2><img src="../images/WptTypes/2.gif" alt="Traditional Cache" width="32" height="32" />&nbsp;Lake Crabtree computer software store</h2> 
      if line =~ /WptTypes.*? alt="(.*?)"/
        if ! @waypointHash.has_key?(wid)
          displayWarning "Found waypoint type, but never saw cache title. Did geocaching.com change their layout again?"
        end
        @waypointHash[wid]['fulltype'] = $1
        @waypointHash[wid]['type'] = $1.split(' ')[0].downcase.gsub(/\-/, '')
        debug "stype=#{@waypointHash[wid]['type']} full_type=#{$1}"
      end
      
      # <p class="Meta"><strong>Difficulty:</strong> <img src="http://www.geocaching.com/images/stars/stars2_5.gif" alt="2.5 out of 5" /></p> 
      if line =~ /Difficulty:.*?([-\d\.]+) out of 5/
        if $1.to_f == $1.to_i
          @waypointHash[wid]['difficulty']=$1.to_i
        else
          @waypointHash[wid]['difficulty']=$1.to_f
        end
        debug "difficulty: #{@waypointHash[wid]['difficulty']}"
      end

      # <p class="Meta"><strong>Terrain:</strong> <img src="http://www.geocaching.com/images/stars/stars2.gif" alt="2 out of 5" /></p> 
      if line =~ /Terrain:.*?([-\d\.]+) out of 5/
        if $1.to_f == $1.to_i
          @waypointHash[wid]['terrain']=$1.to_i
        else
          @waypointHash[wid]['terrain']=$1.to_f
        end
        debug "terrain: #{@waypointHash[wid]['terrain']}"
      end

      # <p class="Meta">Placed Date: 7/17/2001</p> 
      if line =~ /Placed Date: ([\w\/]+)\</
        if $1 != 'N/A'
          @waypointHash[wid]['ctime'] = parseDate($1)
          @waypointHash[wid]['cdays'] = daysAgo(@waypointHash[wid]['ctime'])
          debug "ctime=#{@waypointHash[wid]['ctime']} cdays=#{@waypointHash[wid]['cdays']}"
        end
      end

      if line =~ /with an account to view|You must be logged in/
        displayWarning "Oops, we are not actually logged in!"
        return 'login-required'
      end

      # <p class="Meta"><strong>Size:</strong> <img src="../images/icons/container/regular.gif" alt="Size: Regular" />&nbsp;<small>(Regular)</small></p> 
      if line =~ /\<img src=".*?" alt="Size: (.*?)" \/\>/
        @waypointHash[wid]['size'] = $1.downcase
        debug "found size: #{$1}"
      end

      # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
      if line =~ /=\"LatLon.*\>.*?([NWSE]) (\d+).*? ([\d\.]+) ([NWSE]) (\d+).*? ([\d\.]+)\</
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

      if line =~ /CacheLogs\"\>/
        debug "inspecting comments: #{line}"
        cnum = 0
        funTotal = 0.0
        fnum = 0

        line.gsub!(/\<p\>/, ' ')
        # <img src="http://www.geocaching.com/images/icons/icon_smile.gif" alt="" />&nbsp;January 9 by <a href="/profile/?guid=8e3afe9c-5bc0-44ea-abde-2e5d680b90d5"
        # id="94849032">Happy Wayfarer</a></strong> (215 found)<br />A nice walk early in the morning. There whereno muggles at this time.
        # <br>Made some nice picture from this lovely park and view to the Bosporus and walked back to Eminönü.<p>Thanks from Germany<br>Happy Wayfarer</td>
        line.scan(/\/icon_(\w+)\.gif.*?\>\&nbsp\;([\w, ]+) by \<a href=".*?id=\"(.*?)\"\>(.*?)\<\/a\>.*?\<br \/\>(.*?)\<\/td\>/) { |icon, date, user_id, name, comment|
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
          
          if @waypointHash[wid]['creator'] == name
            debug "not grading comment by owner: #{name}"
            nograde=1
          end

          debug "comment [#{cnum}] is '#{type}' by #{name}[#{user_id}] on #{date}: #{comment}"
          comment.gsub!(/\<.*?\>/, ' ')
          date = Time.parse(date)
          if type == 'Found it' and @waypointHash[wid]['mdays'] == -1
            debug "Found successful comment, updating mtime to #{date}"
            @waypointHash[wid]['mtime'] = date
            @waypointHash[wid]['mdays'] = daysAgo(date)
          end
          @waypointHash[wid]["comment#{cnum}Type"] = type.dup
          @waypointHash[wid]["comment#{cnum}Date"] = date.strftime("%Y-%m-%dT%H:00:00.0000000-07:00")
          @waypointHash[wid]["comment#{cnum}DaysAgo"] = daysAgo(date)
          @waypointHash[wid]["comment#{cnum}ID"] = cnum
          @waypointHash[wid]["comment#{cnum}UID"] = user_id.dup
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
          debug "COMMENT #{cnum}: i=#{icon} d=#{date} n=#{name} c=#{comment} fun=#{fun}"
          cnum = cnum + 1
        }   # no more comments

        @waypointHash[wid]['funfactor']=calculateFun(funTotal, fnum)
      end

    }

    # <div id="div_hint" class="HalfLeft"> 
    #    <div> 
    #        Vs lbh ner pyrire, lbh pna cebonoyl svaq n cnexvat ybg gb fgneg sebz gung jvyy trg lbh pybfre gb gur pnpur. Vs lbh ragre gur pnpur nern sebz gur rnfg lbh jvyy tb vagb gur bcra nern naq gura onpx vagb gur jbbqf. Nsgre lbh ragre gur jbbqf, ybbx sbe n gerr ba gur evtug gung unf gbccyrq jvgu gur onfr orvat evtug ng gur rqtr bs gur cngu (guvf jbhyq or n tbbq cynpr sbe gur pnpur, ohg vg vfa’g urer.) Tb qverpgyl yrsg hc gur uvyy naq ybbx sbe fbzr gbccyrq gerrf. Gur pnpur vf pybfr ol – naq cerggl jryy uvqqra.
    #    </div>
            
    if data =~ /id="div_hint".*?\>(.*?)\s*\<\/div/m
      hint = $1.strip
      hint.gsub!(/^ +/, '')
      hint.gsub!(/[\r\n]/, '')
      hint.gsub!('<br>', ' / ')
      hint.gsub!('<div>', '')
      @waypointHash[wid]['hint'] = hint
      debug "got hint: [#{hint}]"
    end

    # this data is all on one line, so we should just use scan and forget reparsing.
    if (wid)
      debug "we have a wid"
      if data =~ /\<div id="div_sd"\>\s*\<div\>(.*?)\<\/div\>\s*\<\/div\>/m
        shortdesc = $1
        debug "found short desc: [#{shortdesc}]"
        @waypointHash[wid]['shortdesc'] = removeAlignments(fixRelativeImageLinks(removeSpam(shortdesc)))
      end

      if data =~ /\<div id="div_ld"\>\s*\<div\>(.*?)\<\/div\>\s*\<\/div\>/m
        longdesc = $1
        debug "got long desc [#{longdesc}]"
        longdesc = removeAlignments(fixRelativeImageLinks(removeSpam(longdesc)))
        @waypointHash[wid]['longdesc'] = longdesc
      end

      @waypointHash[wid]['details'] = @waypointHash[wid]['shortdesc'] + " ... " + @waypointHash[wid]['longdesc']


      # Parse the additional waypoints table. Needs additional work for non-HTML templates.
      debug "will addit"
      @waypointHash[wid]['additional_raw'] = parseAdditionalWaypoints(data)

    end  # end wid check.

    # How valid is this cache?
    if wid && @waypointHash[wid]['latwritten']
      return 1
    else
      debug "parseCache returning as nil because wid #{wid} has no coordinates (and the login works?)"
      return nil
    end
  end  # end function
  
  def removeAlignments(text)
    new_text = text.gsub(/(\<div .*?)align=/m, '\1noalign=')
    new_text.gsub!(/(\<p .*?)align="/m, '\1noalign=')
    new_text.gsub!('<center>', '')
    if text != new_text
      debug "fixed alignments in #{new_text}"
    end
    return new_text
  end
  
  def fixRelativeImageLinks(text)
    new_text = text.gsub(' src="/', ' src="http://www.geocaching.com/')
    if text != new_text
      debug "fixed relative links in #{new_text}"
    end
    return new_text
  end
  
  def parseAdditionalWaypoints(text)
    debug "additional: #{text}"
    # <p><p><strong>Additional Waypoints</strong></p></p> 
    if text =~ /Additional Waypoints.*?(\<table.*?\/table\>)/m
      additional = $1
      return fixRelativeImageLinks(additional)
    else
      return nil
    end    
  end

  def removeSpam(text)
    # <a href="http://s06.flagcounter.com/more/NOk"><img src= "http://s06.flagcounter.com/count/NOk/bg=E2FFC4/txt=000000/border=CCCCCC/columns=4/maxflags=32/viewers=0/labels=1/pageviews=1/" alt="free counters" /></a>
    removed = text.gsub(/\<a href.*?flagcounter.*?\<\/a\>/m, '')
    removed.gsub!(/\<\/*center\>/, '')
    if removed != text
      debug "Removed spam from: ----------------------------------"
      debug removed
      debug "-----------------------------------------------------"
    end

    return removed
  end

end  # end class
