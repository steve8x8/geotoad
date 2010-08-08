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
      if @waypointHash[id]['guid']
        suffix = 'guid=' + @waypointHash[id]['guid'].to_s
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
    if page.data
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

  def calculateFun(total, num_graded)
    # if no num_graded, it must be at least somewhat interesting!
    if num_graded == 0
      return 3.0
    end

    score=total.to_f / num_graded.to_f

    # a grade of >28 is considered awesome
    # a grade of <-20 is considered pretty bad
    debug "fun total=#{total} num_graded=#{num_graded} score=#{score}"
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
    cache = nil

    data.split("\n").each { |line|
      # <title id="pageTitle">(GC1145) Lake Crabtree computer software store by darylb</title> 
      if line =~ /\<title.*\((GC\w+)\) (.*?) by (.*?)\</
        wid = $1
        name = $2
        creator = $4
        debug "wid = #{wid} name=#{name} creator=#{creator}"
        cache = @waypointHash[wid]
        cache['name'] = name
        cache['creator'] = creator
        # Calculate a semi-unique integer creator id, since we can no longer get it from this page.
        cache['creator_id'] = Zlib.crc32(creator)
        cache['shortdesc'] = ''
        cache['longdesc'] = ''
        cache['details'] = ''
        cache['funfactor'] = 0
        cache['url'] = "http://www.geocaching.com/seek/cache_details.aspx?wp=" + wid

        if not cache['mtime']
          cache['mdays'] = -1
          cache['mtime'] = Time.at(0)
        end
      end

      # <h2><img src="../images/WptTypes/2.gif" alt="Traditional Cache" width="32" height="32" />&nbsp;Lake Crabtree computer software store</h2> 
      if line =~ /WptTypes.*? alt="(.*?)"/
        if ! cache
          displayWarning "Found waypoint type, but never saw cache title. Did geocaching.com change their layout again?"
        end
        cache['fulltype'] = $1
        cache['type'] = $1.split(' ')[0].downcase.gsub(/\-/, '')
        debug "stype=#{cache['type']} full_type=#{$1}"
      end
      
      # <p class="Meta"><strong>Difficulty:</strong> <img src="http://www.geocaching.com/images/stars/stars2_5.gif" alt="2.5 out of 5" /></p> 
      if line =~ /Difficulty:.*?([-\d\.]+) out of 5/
        if $1.to_f == $1.to_i
          cache['difficulty']=$1.to_i
        else
          cache['difficulty']=$1.to_f
        end
        debug "difficulty: #{cache['difficulty']}"
      end

      # <p class="Meta"><strong>Terrain:</strong> <img src="http://www.geocaching.com/images/stars/stars2.gif" alt="2 out of 5" /></p> 
      if line =~ /Terrain:.*?([-\d\.]+) out of 5/
        if $1.to_f == $1.to_i
          cache['terrain']=$1.to_i
        else
          cache['terrain']=$1.to_f
        end
        debug "terrain: #{cache['terrain']}"
      end

      # <p class="Meta">Placed Date: 7/17/2001</p> 
      if line =~ /Placed Date: ([\w\/]+)\</
        if $1 != 'N/A'
          cache['ctime'] = parseDate($1)
          cache['cdays'] = daysAgo(cache['ctime'])
          debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"
        end
      end

      if line =~ /with an account to view|You must be logged in/
        displayWarning "Oops, we are not actually logged in!"
        return 'login-required'
      end

      # <p class="Meta"><strong>Size:</strong> <img src="../images/icons/container/regular.gif" alt="Size: Regular" />&nbsp;<small>(Regular)</small></p> 
      if line =~ /\<img src=".*?" alt="Size: (.*?)" \/\>/
        cache['size'] = $1.downcase
        debug "found size: #{$1}"
      end

      # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
      if line =~ /=\"LatLon.*\>.*?([NWSE]) (\d+).*? ([\d\.]+) ([NWSE]) (\d+).*? ([\d\.]+)\</
        cache['latwritten'] = $1 + $2 + ' ' + $3
        cache['lonwritten'] = $4 + $5 + ' ' + $6
        cache['latdata'] = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
        cache['londata'] = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
        debug "got written lat/lon"
      end

      # why a geocache is closed. It seems to always be the same.
      # <span id="ctl00_ContentBody_ErrorText"><p class="OldWarning"><strong>Cache Issues:</strong></p><ul class="OldWarning"><li>This cache is temporarily unavailable. Read the logs below to read the status for this cache.</li></ul></span>
      if line =~ /ErrorText\".*?>(.*?)\<\/span\>/
        warning = $1
        warning.gsub!(/\<.*?\>/, '')
        debug "got a warning: #{warning}"
        if (wid)
          cache['warning'] = warning.dup
        end
        if warning =~ /Premium Member/
          debug "This cache appears to be available to premium members only."
          return 'subscriber-only'
        end
      end
    }

    # Short-circuit and abort if the data is no good.
    if not cache:
      displayWarning "Unable to parse any cache details from data."
      return false
    elsif not cache['latwritten']
      displayWarning "#{cache['wid']} was parsed, but no coordinates found."
      return false
    end
    
    
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
      cache['hint'] = hint
      debug "got hint: [#{hint}]"
    end
    
    if data =~ /\<div id="div_sd"\>\s*\<div\>(.*?)\<\/div\>\s*\<\/div\>/m
      shortdesc = $1
      debug "found short desc: [#{shortdesc}]"
      cache['shortdesc'] = removeAlignments(fixRelativeImageLinks(removeSpam(shortdesc)))
    end

    if data =~ /\<div id="div_ld"\>\s*\<div\>(.*?)\<\/div\>\s*\<\/div\>/m
      longdesc = $1
      debug "got long desc [#{longdesc}]"
      longdesc = removeAlignments(fixRelativeImageLinks(removeSpam(longdesc)))
      cache['longdesc'] = longdesc
    end

    # Parse the additional waypoints table. Needs additional work for non-HTML templates.
    comments, last_find, fun_factor = parseComments(data, cache['creator'])
    cache[comments] = comments
    if cache['mdays'] == -1 and last_find:
      cache['mtime'] = last_find
      cache['mdays'] = daysAgo(cache['mtime'])
    end
    cache['funfactor'] = fun_factor      
    cache['additional_raw'] = parseAdditionalWaypoints(data)
    cache['details'] = cache['shortdesc'] + " ... " + cache['longdesc']
    return cache
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

  def parseComments(data, creator)
    comments = []
    visitors = []
    last_find = nil
    total_grade = 0
    graded = 0
  
    # <dt>[<img src='http://www.geocaching.com/images/icons/icon_smile.gif' alt="Found it" />&nbsp;Found it] Saturday, April 03, 2010 by <strong>SirPatrick</strong> (143 found) </dt> 
    # <dd>Coordinates were spot on.  Found myself within 6 feet of the cache when I first got to the zone but could not find this very well hid cache. Found it after a few minutes of searching.  Nice hide.  SL TFTH.  
    # </dd>
    data.scan(/<dt.*?icon_(\w+).*?alt=\"(.*?)\".*?, ([\w, ]+) by \<strong\>(.*?)\<\/strong\>.*?\<dd\>(.*?)\<\/dd\>/m) { |icon, type, datestr, user, comment|
      should_grade = true
      grade = 0
      date = Time.parse(datestr)

      if icon == 'smile':
        visitors << user
        if not last_find:
          last_find = Time.parse(datestr)
        end
      elsif icon == 'remove' or icon == 'disabled' or icon == 'greenlight' or icon == 'maint':
        should_grade = false
      end
        
      if user == creator:
        debug "comment from creator #{creator}, not grading"
        should_grade = false
      end

      if should_grade:
        good_or_bad = @@bayes.guess(comment)
        if good_or_bad[0] && good_or_bad[1]
          grade = (good_or_bad[1][1] - good_or_bad[0][1]) * 100
          # Put an upper cap on goodness
          if grade > 28.0
            grade = 28.0
          end
          graded =+ 1
          total_grade =+ grade
        end
      end
      
      comment = {
        'type' => type,
        'date' => date,
        'icon' => icon,
        'user' => user,
        'user_id' => Zlib.crc32(user),
        'comment' => comment,
        'grade' => grade
      }
      debug "COMMENT: #{comment.inspect}"      
    }
    return [comments, last_find, calculateFun(total_grade, graded)]
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
