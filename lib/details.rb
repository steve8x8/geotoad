# -*- encoding : utf-8 -*-

require 'time'
require 'zlib'
require 'lib/common'
require 'lib/messages'
require 'lib/geodist'
require 'lib/logbook'
require 'lib/gallery'

class CacheDetails

  include Common
  include Messages
  # only required for "moved PMO":
  include GeoDist
  include LogBook
  include Gallery

  # Use a printable template that shows the last 10 logs.
  @@baseURL = "https://www.geocaching.com/seek/cdpf.aspx"

  attr_writer :preserve
  attr_writer :getlogbk
  attr_writer :getimage

  def initialize(data)
    @waypointHash = data
    @preserve = nil
    @getlogbk = nil
    @getimage = nil

    @cachetypenum = {
	'2'	=> 'Traditional Cache',
	'3'	=> 'Multi-cache',
	'4'	=> 'Virtual Cache',
	'5'	=> 'Letterbox Hybrid',
	'6'	=> 'Event Cache',
	'8'	=> 'Unknown Cache', # now: 'Mystery Cache',
	'9'	=> 'Project APE Cache',
	'11'	=> 'Webcam Cache',
	'12'	=> 'Locationless (Reverse) Cache',
	'13'	=> 'Cache In Trash Out Event',
	'137'	=> 'EarthCache',
	'453'	=> 'Mega-Event Cache',
	'1304'	=> 'GPS Adventures Exhibit',
	'1858'	=> 'Wherigo Cache',
	'3653'	=> 'Lost and Found Event Cache',
	'3773'	=> 'Groundspeak HQ', # now: 'Geocaching HQ',
	'3774'	=> 'Groundspeak Lost and Found Celebration',
	'4738'	=> 'Geocaching Block Party',
	'7005'	=> 'Giga-Event Cache',
	'cito'		=> 'Cache In Trash Out Event',
	'earthcache'	=> 'EarthCache',
	'event'		=> 'Event Cache',
	'giga'		=> 'Giga-Event Cache',
	'locationless'	=> 'Locationless (Reverse) Cache',
	'maze'		=> 'GPS Adventures Exhibit',
	'mega'		=> 'Mega-Event Cache',
	'multi'		=> 'Multi-cache',
	'traditional'	=> 'Traditional Cache',
	'unknown'	=> 'Unknown Cache', # now: 'Mystery Cache',
	'virtual'	=> 'Virtual Cache',
	'webcam'	=> 'Webcam Cache',
	'wherigo'	=> 'Wherigo Cache',
    }
  end

  def waypoints
    @waypointHash
  end

  def baseURL
    @@baseURL
  end

#  # this routine is for compatibility.
#  def fetchWid(id)
#    fetch(id)
#  end

  def getRemoteMapping(wid)
    # get guid from gallery RSS
    guid = getRemoteMapping3(wid)
    return [guid, '3'] if guid
    # get guid from cache_details page
    guid = getRemoteMapping1(wid)
    return [guid, '1'] if guid
    # get guid from log entry page
    guid = getRemoteMapping2(wid)
    return [guid, '2'] if guid
    return [nil, '0']
  end

  def getRemoteMapping1(wid)
    debug "Get GUID from cache_details for #{wid}"
    # extract mapping from cache_details page
    guid = nil
    @pageURL = 'https://www.geocaching.com/seek/cache_details.aspx?wp=' + wid
    page = ShadowFetch.new(@pageURL)
    page.localExpiry = -1
    data = page.fetch
    if data =~ /cdpf\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug2 "Found GUID: #{guid}"
      return guid
    end
    debug "Could not map(1) #{wid} to GUID"
    return nil
  end

  def getRemoteMapping2(wid)
    debug "Get GUID from log submission page for #{wid}"
    # log submission page contains guid of cache [2016-04-30]
    logid = cacheID(wid)
    guid = nil
    @pageURL = 'https://www.geocaching.com/seek/log.aspx?ID=' + logid.to_s + '&lcn=1'
    page = ShadowFetch.new(@pageURL)
    page.localExpiry = -1
    data = page.fetch
    if data =~ /The listing has been locked/m
      displayWarning "#{wid} logbook is locked, cannot map"
    end
    if data =~ /cache_details\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug2 "Found GUID: #{guid}"
      return guid
    end
    debug "Could not map(2) #{wid} to GUID"
    return nil
  end

  def getRemoteMapping3(wid)
    debug "Get GUID from gallery for #{wid}"
    # extract mapping from cache_details page
    guid = nil
    @pageURL = 'https://www.geocaching.com/datastore/rss_galleryimages.ashx?id=' + cacheID(wid).to_s
    page = ShadowFetch.new(@pageURL)
    page.localExpiry = -1
    page.useCookie = false
    page.closingHTML = false
    data = page.fetch
    if data =~ /cache_details\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug2 "Found GUID: #{guid}"
      return guid
    end
    debug "Could not map(3) #{wid} to GUID"
    return nil
  end

  def fullURL(id)
    if (id =~ /^GC/)
      # look up guid
      if not @waypointHash[id]['guid']
        # there is no cdpf.aspx?wp=...
        guid = getMapping(id.to_s)
        debug2 "dictionary maps #{id.inspect} to #{guid.inspect}"
        if not guid
          # it's not in the dictionary; try to map
          guid, src = getRemoteMapping(id.to_s)
        end
        if not guid
          # no way
          displayWarning "Could not map #{id.inspect} to GUID"
          return nil
        end
        debug2 "mapped #{id.inspect} to #{guid.inspect}"
        appendMapping(id, guid, "(#{src})")
        @waypointHash[id]['guid'] = guid
      end
      suffix = 'guid=' + @waypointHash[id]['guid'].to_s
    else
      suffix = 'guid=' + id.to_s
    end
    return @@baseURL + "?" + suffix + "&lc=10"
  end

  # fetches by geocaching.com sid
  def fetchWid(id)
    if id.to_s.empty?
      displayError "Empty fetch by wid, quitting."
      exit
    end

    url = fullURL(id)
    # no valid url (wid doesn't point to guid)
    return [nil, nil] if url.to_s.empty?
    page = ShadowFetch.new(url)

    # Tune expiration for young caches:
    # Caches which are only a few days old should be updated more often
    # to get hold of recent logs (criticism, hints, coord updates)
    ttl = nil
    if (id =~ /^GC/)
      if @waypointHash[id]['guid']
        age = @waypointHash[id]['cdays']
        if age
          # favour caches with small "absolute age"
          if age.abs <= 10
            ttl = age.abs * 86400 / 2
            debug2 "age: #{id} (#{age}, event #{@waypointHash[id]['event'].inspect}) ttl=#{ttl}"
          end
        else
          debug "no creation date found for #{id}"
        end
      end
    end

    # overwrite TTL if "preserveCache" option was set
    if @preserve
      ttl = 333000000		# > 10 years
    end

    if ttl
      page.localExpiry = ttl
    end
    page.fetch()
    src = page.src
    if page.data
      success = parseCache(page.data)
    else
      debug "No data found, not attempting to parse the entry at #{url}"
      success = nil
    end

    # success is hash; nil or string if problem
    if success.class != Hash
      message = "Could not parse #{url}."
      if success.class == String
        message << " (#{success})"
      end
      debug message
    end
    return [success, src]
  end

# calculate fav factor
# 1st approach: ignore pre-fav times (before Feb 1, 2011)
# best: 10 of 10 -> 5.0
# avg :  1 of 10 -> ~2.5
# bad : 1 of 100 -> ~0
  def calculateFav(fav, found)
    scalingfactor = 1.0			# roughly
    favinfavperiod = (fav || 0)		# obviously
    foundinfavperiod = (found || 1)	# unfair to older caches!
    quot = favinfavperiod.to_f / foundinfavperiod
    if (quot > 0.0)
      logquot = 5.0 + scalingfactor * Math.log(quot)
      logquot = 0.0 if (logquot < 0.0)
      logquot = 5.0 if (logquot > 5.0)
    else
      logquot = 0.0
    end
    return (10*logquot).round.to_f / 10.0
  end

  # Parse attributes: convert name of image into index and yes/no value
  def parseAttr(text)
    # "bicycles-yes" -> 32, 1
    attrmap = {
      "attribute-blank"  =>  0,
      "dogs"             =>  1,
      "fee"              =>  2,
      "rappelling"       =>  3,
      "boat"             =>  4,
      "scuba"            =>  5,
      "kids"             =>  6,
      "onehour"          =>  7,
      "scenic"           =>  8,
      "hiking"           =>  9,
      "climbing"         => 10,
      "wading"           => 11,
      "swimming"         => 12,
      "available"        => 13,
      "night"            => 14,
      "winter"           => 15,
      "16"               => 16,
      "poisonoak"        => 17,
      "dangerousanimals" => 18,
      "ticks"            => 19,
      "mine"             => 20,
      "cliff"            => 21,
      "hunting"          => 22,
      "danger"           => 23,
      "wheelchair"       => 24,
      "parking"          => 25,
      "public"           => 26,
      "water"            => 27,
      "restrooms"        => 28,
      "phone"            => 29,
      "picnic"           => 30,
      "camping"          => 31,
      "bicycles"         => 32,
      "motorcycles"      => 33,
      "quads"            => 34,
      "jeeps"            => 35,
      "snowmobiles"      => 36,
      "horses"           => 37,
      "campfires"        => 38,
      "thorn"            => 39,
      "stealth"          => 40,
      "stroller"         => 41,
      "firstaid"         => 42,
      "cow"              => 43,
      "flashlight"       => 44,
      "landf"            => 45,
      "rv"               => 46,
      "field_puzzle"     => 47,
      "uv"               => 48,
      "snowshoes"        => 49,
      "skiis"            => 50,
      "s-tool"           => 51,
      "nightcache"       => 52,
      "parkngrab"        => 53,
      "abandonedbuilding"=> 54,
      "hike_short"       => 55,
      "hike_med"         => 56,
      "hike_long"        => 57,
      "fuel"             => 58,
      "food"             => 59,
      "wirelessbeacon"   => 60,
      "partnership"      => 61,
      "seasonal"         => 62,
      "touristok"        => 63,
      "treeclimbing"     => 64,
      "frontyard"        => 65,
      "teamwork"         => 66,
      "geotour"          => 67,
      # obsolete?, but image still exists
      "snakes"           => 18,
      "sponsored"        => 61,
    }
    if text == "attribute-blank"
      return 0, 0
    end
    what = text.gsub(/(.*)-.*/, "\\1") # only strip "yes" or "no"!
    how = text.gsub(/^.*-/, "")
    # get mapping
    attrid = attrmap[what.downcase]
    attrval = (how.downcase == "yes") ? 1 : 0
    if not attrid
      # we may have missed an addition or change to the list
      displayWarning "Unknown attribute #{text}, please report!"
      return 0, 0
    end
    return attrid, attrval
  end

  def parseCache(data)
    # find the geocaching waypoint id.
    wid = nil
    cache = nil
    nextline_coords = false

    # catch bad input data
    begin
    # start with single-line matches
    data.split("\n").each{ |line|
      # <title id="pageTitle">(GC1145) Lake Crabtree computer software store by darylb</title>
      # but: (without parentheses!)
      # <title id="pageTitle">GCFD21 Grandma&#39;s idea by gopackers</title>
      if line =~ /<title.*>\(?(GC\w+)\)? \s*(.*? by .*?)\s*</
        wid = $1
        namecreator = $2
        name = nil
        creator = nil
        # if multiple "by", trust what search told us
        if namecreator =~ /(.*) by (.*)/
          name = $1
          creator = $2
          if namecreator =~ /by .* by/
            debug2 "Could not determine unambiguously name and creator"
          end
        end
        debug "wid = #{wid} name=#{name} creator=#{creator}"
        cache = @waypointHash[wid]
        if not cache.key?('visitors')
          cache['visitors'] = []
        end
        if name and creator
          # do not overwrite what we might have got from search
          if not cache['name']
            cache['name'] = name.gsub(/^\s+/, '').gsub(/\s+$/, '').gsub(/\s+/, ' ')
          end
          if not cache['creator']
            cache['creator'] = creator.gsub(/^\s+/, '').gsub(/\s+$/, '').gsub(/\s+/, ' ')
          end
          # Calculate a semi-unique integer creator id, since we can no longer get it from this page.
          cache['creator_id'] = Zlib.crc32(cache['creator'])
        end
        cache['shortdesc'] = ''
        cache['longdesc'] = ''
        cache['comments'] = []
        cache['favfactor'] = 0
#        cache['url'] = "http://www.geocaching.com/geocache/" + wid
        cache['url'] = "http://coord.info/" + wid
      end

      # <h2>
      #     <img src="../images/WptTypes/2.gif" alt="Traditional Cache" width="32" height="32" />&nbsp;Lake Crabtree computer software store
      # </h2>
      if line =~ /WptTypes\/(\w+)\.[^>]* alt=\"(.*?)\".*?\/>(.nbsp;)?\s*(.*?)\s*$/
        debug "found ccode=#{$1}, type=#{$2} name=#{$4}"
        ccode = $1
        full_type = $2
        name = $4
        # traditional_72 etc.
        if ccode =~ /^(\w+)_\d+/
          ccode = $1
        end
        if @cachetypenum[ccode]
          full_type = @cachetypenum[ccode]
        else
          displayWarning "Cache image code #{ccode} for #{full_type} - please report"
        end
        if not cache
          displayWarning "Found waypoint type, but never saw cache title. Did geocaching.com change their layout again?"
        end
        debug "Found alternative name #{name.inspect}"
        cache['name2'] = name.gsub(/^\s+/, '').gsub(/\s+$/, '').gsub(/\s+/, ' ')
        # there may be more than 1 match, don't overwrite (see GC1PQKR, GC1PQKT)
        # actually, types have been set by search - is this code obsolete then?
        if cache['fulltype']
          debug "Not overwriting \"#{cache['fulltype']}\"(#{cache['type']}) with \"#{full_type}\""
        else
          cache['fulltype'] = full_type
          cache['type'] = full_type.split(' ')[0].downcase.gsub(/\-/, '')
          # special cases
          case full_type
          when /Cache In Trash Out/
            cache['type'] = 'cito'
          when /Lost and Found Celebration/
            cache['type'] = 'lfceleb'
          when /Lost and Found Event/
            cache['type'] = 'lost+found'
          when /Project APE Cache/
            cache['type'] = 'ape'
          when /Groundspeak HQ/
            cache['type'] = 'gshq'
          when /Geocaching HQ/
            cache['type'] = 'gshq'
          when /Locationless/
            cache['type'] = 'reverse'
          when /Block Party/
            cache['type'] = 'block'
          when /Exhibit/
            cache['type'] = 'exhibit'
          # planned transition
          when /Mystery/
            cache['fulltype'] = 'Unknown Cache'
            cache['type'] = 'unknown'
          # 2014-08-26 - obsolete?
          when /Traditional/
            cache['fulltype'] = 'Traditional Cache'
            cache['type'] = 'traditional'
          when /Earth/
            cache['fulltype'] = 'Earthcache'
            cache['type'] = 'earthcache'
          end
          if full_type =~ /Event/
            cache['event'] = true
          end
          debug "stype=#{cache['type']} full_type=#{cache['fulltype']}"
        end
      end

      if line =~ /with an account to view|You must be logged in/
        displayWarning "Oops, we are not actually logged in!"
        return 'login-required'
      end

      # <p class="Meta">\s*<strong>Size:</strong>\s*<img src="../images/icons/container/regular.gif" alt="Size: Regular" />&nbsp;<small>(Regular)</small>\s*</p>
      # match only image part
      if line =~ /<img src=\".*?\" alt=\"Size: (.*?)\" \/>/
        if not cache['size']
          cache['size'] = $1.downcase.gsub(/medium/, 'regular')
        end
        debug "found size: #{$1}"
      end

      # latitude and longitude in the written form. Rewritten by Scott Brynen for Southpole compatibility.
      if line =~ /=\"LatLong Meta\">/
        nextline_coords = true
      end
      # changed 2014-01-14
      if nextline_coords and (line =~ /([NS]) (\d+).*? ([\d\.]+) ([EW]) (\d+).*? ([\d\.]+)/)
        cache['latwritten'] = $1 + ' ' + $2 + '° ' + $3
        cache['lonwritten'] = $4 + ' ' + $5 + '° ' + $6
        cache['latdata'] = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1 : 1)
        cache['londata'] = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1 : 1)
        debug "got written lat/lon #{cache['latdata']}/#{cache['londata']}"
        nextline_coords = false
      end

      # why a geocache is closed. It seems to always be the same.
      # <span id="ctl00_ContentBody_ErrorText"><p class="OldWarning"><strong>Cache Issues:</strong></p><ul class="OldWarning"><li>This cache is temporarily unavailable. Read the logs below to read the status for this cache.</li></ul></span>
      if line =~ /Warning\".*?>(.*?)</
        warning = $1
        warning.gsub!(/<.*?>/, '')
        debug "got a warning: #{warning}"
        if wid
          if warning =~ /has been archived/
            if cache['archived'].nil?
              debug "last resort setting cache to archived"
              cache['archived'] = true
            else
              debug "outdated information: archived"
            end
          end
          if warning =~ /is temporarily unavailable/
            if cache['disabled'].nil?
              debug "last resort setting cache to disabled"
              cache['disabled'] = true
            else
              debug "outdated information: disabled"
            end
          end
          cache['warning'] = warning.dup
        end
        if warning =~ /be a Premium Member to view/
          # 'archived' should have been set by search
          debug "This cache appears to be available to premium members only."
          # do not return 'subscriber-only', take care of missing info later!
          cache['membersonly'] = true
        end
      end

      # extract attributes assigned, and their value, plus the short text
      # ...<a href="/about/icons.aspx" title="Wat zijn eigenschappen?">...
      if line =~ /a href=\"\/about\/icons.aspx\" title=/
        debug3 "inspecting attributes: #{line}"
        # list of attributes only in cdpf version :(
        # cumulative text
        atxt = Array.new
        # attribute counter
        anum = 0
        # is this really necessary?
        line.gsub!(/<p[^>]*>/, '')
        # <img src="/images/attributes/bicycles-no.gif" alt="no bikes" width="30" height="30" />
        line.scan(/\/images\/attributes\/(.+?)\.gif. alt=\"(.*?)\"[^>]*\/>/){ |icon, alt|
          # convert each image name into index/value pair, keep related text
          aid, ainc = parseAttr(icon)
          debug3 "attribute #{anum}: ic=#{icon} id=#{aid} inc=#{ainc} alt=#{alt} "
          if aid > 0
            # make this a 3d array instead? ...['attributes'][aid]=ainc
            cache["attribute#{anum}id"] = aid
            cache["attribute#{anum}inc"] = ainc
            cache["attribute#{anum}txt"] = alt
            atxt << alt
            anum += 1
          end
        }   # no more attributes
        # keep the collected text in wp hash, for GPSr units to show
        cache['attributeText'] = atxt.join(', ')
        cache['attributeCount'] = anum
        debug "Found #{anum} attributes: #{atxt}"
      end

      # wherigo cartridge link
      # http://www.wherigo.com/cartridge/details.aspx?CGUID=...
      # http://www.wherigo.com/cartridge/download.aspx?CGUID=...
      if line =~ /(www\.wherigo\.com\/cartridge\/\w+.aspx\?CGUID=([0-9a-f-]{36}))/
        debug "Wherigo cartridge at #{$1}"
        # do not overwrite with later ones
        if not cache['cartridge']
          cache['cartridge'] = $2
        end
      end

      if line =~ /^\s*<h\d>Cache is Unpublished<\/h\d>\s*$/i
        return "unpublished"
      end

      # last resort to get coordinates - from JavaScript line (at end)
      if line =~ /^var lat=(-?[0-9\.]+), lng=(-?[0-9\.]+),/
        jslat = $1
        jslon = $2
        debug "got javascript lat/lon #{jslat}/#{jslon}"
        # (1) normal behaviour (BM doesn't see PMO coords)
        if not cache['membersonly'] and ( not cache['latdata'] or not cache['londata'] )
        # (2) only fill in if nothing there (ignore moved caches with old desc)
        #if ( not cache['latdata'] or not cache['londata'] )
        # (3) get the most of all available information (old & new PMO location)
        #if cache['membersonly'] or ( not cache['latdata'] or not cache['londata'] )
          oldlat = cache['latdata']
          oldlon = cache['londata']
          cache['latdata'] = jslat
          cache['londata'] = jslon
          newlat = jslat
          newlon = jslon
          # "written" style, whatever that's good for.
          cache['latwritten'] = lat2str(jslat, degsign="°")
          cache['lonwritten'] = lon2str(jslon, degsign="°")
          if cache['membersonly']
            debug "rewrite lat/lon for PMO #{wid}"
          else
            debug "last resort lat/lon for #{wid}"
          end
          if ( oldlat and oldlon ) and
             ( ( (newlat.to_f - oldlat.to_f).abs + (newlon.to_f - oldlon.to_f).abs ) > 0.00001 )
            # cache has moved, description and hint may be inaccurate - set mark
            movedDistance, movedDirection = geoDistDir(oldlat, oldlon, newlat, newlon)
            movedDistance = (movedDistance.to_f * 1000 * $MILE2KM).round
            displayInfo "Moved from #{oldlat}/#{oldlon} to #{newlat}/#{newlon} (#{movedDistance}m@#{movedDirection})"
            cache['moved'] = true
          end
        end
      end
      # 2013-02-05: additional info in "var lat=..." line, but ignore []
      # ;cmapAdditionalWaypoints = [{"lat":54.1835,"lng":12.87963,"type":218,"name":"GC3QN0F Stage 2 ( Question to Answer )","pf":"S2"},{...}];
      if (line =~ /;cmapAdditionalWaypoints\s*=\s*\[(.+)\];/)
        cache['additional_raw2'] = parseMapWaypoints($1)
      end
    }
    rescue => error
      displayWarning "Error in parseCache():data.split"
      if data =~ /<title.*>\((GC\w+)\) (.*?) by (.*?)\s*</
        displayWarning "WID affected: #{$1}"
      end
      raise error
    end

    # Short-circuit and abort if the data is no good.
    if not cache
      displayWarning "Unable to parse any cache details from data."
      return nil
    elsif not cache['latwritten']
      displayWarning "No coordinates found for #{wid}."
      debug2 "no-coords: #{cache.inspect}"
      if cache['membersonly']
        return 'subscriber-only'
      end
      return 'no-coords'
    end

    # MULTI-LINE MATCHES BELOW

    # <p class="Meta">\s*Placed Date: 7/17/2001\s*</p>
    # also, event dates.
    if data =~ />\s*(Placed|Event) Date\s*:\s*([\w \/\.-]+)\s*</m
        what = $1
        date = $2
        debug2 "#{$1}: #{$2}"
        if date != 'N/A'
          # do not overwrite what we got from search
          ctime = parseDate(date)
          if not cache['ctime']
            cache['ctime'] = ctime
          elsif (ctime != cache['ctime'])
            debug2 "ctime changed?: " + cache['ctime'].getlocal.strftime("%Y-%m-%d") + " -> " + ctime.getlocal.strftime("%Y-%m-%d")
          end
          cache['cdays'] = daysAgo(cache['ctime'])
          if what =~ /Event/
            cache['event'] = true
          end
          debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"
        end
    end

    # Owner:
    # <div class="HalfLeft">
    #     <p class="Meta">
    #         Hosted by:
    #         Hasemann-Rudow</p>
    # </div>
    # FIXME: This one may be language-sensitive!
    # (But if we don't find creator2, a found name2 won't be effective.)
    # changed 2014-01-14
    if data =~ /<div class=\"HalfLeft\">\s*<p class=\"Meta\">\s*(.*?):\s*(.*?)\s*<\/p>\s*<\/div>/m
      debug "Found alternative creator #{$2.inspect}"
      creator = $2
      cache['creator2'] = creator.gsub(/^\s+/, '').gsub(/\s+$/, '').gsub(/\s+/, ' ')

    end

    if data =~ /Difficulty:.*?([\d\.]+) out of 5/m
      if not cache['difficulty']
        cache['difficulty'] = tohalfint($1)
      end
      debug "difficulty: #{cache['difficulty']}"
    end

    if data =~ /Terrain:.*?([\d\.]+) out of 5/m
      if not cache['terrain']
        cache['terrain'] = tohalfint($1)
      end
      debug "terrain: #{cache['terrain']}"
    end

    # to compute a fav rate we need the total found count
    if data =~ /alt=\"Found it\" \/>&nbsp;(\d+)&nbsp;Found it/
      cache['foundcount'] = $1.to_i
      cache['favfactor'] = calculateFav(cache['favorites'], cache['foundcount'])
      debug "found: #{cache['foundcount']} favs: #{cache['favorites']} favfactor: #{cache['favfactor']}"
    end

    if data =~ /id=\"uxDecryptedHint\".*?>\s*(.*?)\s*<\/div/m
      hint = $1.strip
      if hint =~ /[<>]/
        debug2 "Hint contains HTML: #{hint}"
      end
      hint.gsub!(/^ +/, '')
      # remove whitespace/linebreaks
      hint.gsub!(/\s*[\r\n]+\s*/, '|')
      hint.gsub!(/\s*<[bB][rR] *\/?>\s*/, '|')
      hint.gsub!('<div>', '')
      # only one linebreak
      hint.gsub!(/\|\|+/, '|')
      cache['hint'] = hint
      debug "got hint: [#{hint}]"
    end

    if data =~ /Short Description\s*<\/h2>\s*<\/div>\s*<div class=\"item-content\">(.*?)<\/div>\s*<\/div>\s*<div class=\"item\">/m
      shortdesc = $1.gsub(/^\s+/, '').gsub(/\s+$/, '')
      debug3 "got short desc: [#{shortdesc}]"
      cache['shortdesc'] = removeAlignments(fixRelativeImageLinks(removeSpam(removeSpan(shortdesc))))
    end

    if data =~ /Long Description\s*<\/h2>\s*<\/div>\s*<div class=\"item-content\">(.*?)<\/div>\s*<\/div>\s*<div class=\"item\">/m
      longdesc = $1.gsub(/^\s+/, '').gsub(/\s+$/, '')
      debug3 "got long desc [#{longdesc}]"
      longdesc = removeAlignments(fixRelativeImageLinks(removeSpam(removeSpan(longdesc))))
      cache['longdesc'] = longdesc
    end

    # <h2>\n   Trackable Items</h2>\n   </div>\n   <div class="item-content">\n   (empty)\n   </div>
    # ... <img src="http://www.geocaching.com/images/wpttypes/sm/21.gif" alt="" /> SCOUBIDOU, <img src="http://www.geocaching.com/images/wpttypes/sm/3916.gif" alt="" /> colorful kite ...
    if data =~ /<h\d>\s*Trackable Items\s*<\/h\d>\s*<\/div>\s*<div [^>]*>\s*(.*?)\s*<\/div>/
      # travel bug data, all in a single line
      line = $1
      debug2 "List of trackables: #{line}"
      trackables = ''
      # split at icon tag, drop everything before
      line.gsub(/^.*?</, '').split(/</).each{ |item|
        debug2 "trackable item #{item}"
        item.gsub!(/[^>]*>\s*/, '')
        item.gsub!(/[,\s]*$/, '')
        # shorten the name a bit
        item.gsub!(/^Geocoins:\s+/, '')
        item.gsub!(/Travel Bug( Dog Tag)?/, 'TB')
        item.gsub!(/Geocoin/, 'GC')
        item.gsub!(/^The /, '')
        debug2 "trackable in list #{item}"
        trackables << item + ', '
      }
      if trackables.length > 0
        trackables.gsub!(/, $/, '')
        debug "Trackables Found: #{trackables}"
        cache['travelbug'] = trackables
      end
    end

    # Page Generated on
    # 09/11/2011 18:04:45</p>
    if data =~ />\s*Page Generated [Oo]n\s*(\d+)\/(\d+)\/(\d+)\s(\d+:\d+:\d+)\s*<\/p>/m
      begin
        cache['ltime'] = Time.parse("#{$3}-#{$1}-#{$2} #{$4} PDT/PST")
        cache['ldays'] = daysAgo(cache['ltime'])
        debug "Generated #{$3}-#{$1}-#{$2} #{$4} parsed as #{cache['ltime']} (#{cache['ldays']}d)"
      rescue
        debug "Cannot parse Generated"
      end
    end

    if not cache['ltime']
      cache['ldays'] = -1
      cache['ltime'] = Time.at($ZEROTIME)
    end

    # Log counts:
    #   <p class="Meta">
    #   Log Counts:
    #   <img src="../images/icons/icon_smile.gif" alt="Found it" />&nbsp;71&nbsp;Found it&nbsp;<img src="../images/icons/icon_sad.gif" alt="Didn't find it" />&nbsp;9&nbsp;Didn't find it&nbsp;<img src="../images/icons/icon_note.gif" alt="Write note" />&nbsp;8&nbsp;Write note&nbsp;<img src="../images/icons/traffic_cone.gif" alt="Archive" />&nbsp;1&nbsp;Archive&nbsp;<img src="../images/icons/traffic_cone.gif" alt="Unarchive" />&nbsp;1&nbsp;Unarchive&nbsp;<img src="../images/icons/icon_disabled.gif" alt="Temporarily Disable Listing" />&nbsp;1&nbsp;Temporarily Disable Listing&nbsp;<img src="../images/icons/icon_enabled.gif" alt="Enable Listing" />&nbsp;1&nbsp;Enable Listing&nbsp;<img src="../images/icons/icon_greenlight.gif" alt="Publish Listing" />&nbsp;1&nbsp;Publish Listing&nbsp;<img src="../images/icons/icon_needsmaint.gif" alt="Needs Maintenance" />&nbsp;3&nbsp;Needs Maintenance&nbsp;<img src="../images/icons/icon_maint.gif" alt="Owner Maintenance" />&nbsp;1&nbsp;Owner Maintenance&nbsp;<img src="../images/icons/big_smile.gif" alt="Post Reviewer Note" />&nbsp;1&nbsp;Post Reviewer Note&nbsp;</p>
    if data =~ /<p class=\"Meta\">\s*(<strong>)?Log Counts:(<\/strong>)?\s*(<img.*?)\s*<\/p>/m
      logcounts = $3.gsub(/<img[^>]*>/, '').gsub(/\&nbsp;/, ' ')
      cache['logcounts'] = logcounts
      debug "Found log counts: #{logcounts}"
    end

    if not cache['mtime']
      cache['mdays'] = -1
      cache['mtime'] = Time.at($ZEROTIME)
    end
    if not cache['atime']
      cache['adays'] = -1
      cache['atime'] = Time.at($ZEROTIME)
    end

    # Parse the additional waypoints table. Needs additional work for non-HTML templates.
    comments, last_find_date, visitors = parseComments(data, cache['creator'])
    cache['visitors'] << visitors
    if comments.length > 0 and cache['membersonly']
      # there are logs, cache was not PMO before
      cache['olddesc'] = true
    end
    # do we want to retrieve the geocache.logbook?
    if @getlogbk
      # even if there are old logs from pre-PMO times
      if comments.length <= 0 or cache['membersonly']
        # try to get log entries from logbook page instead
        debug "Get logbook for guid #{cache['guid']}"
        newcomments, logtimestamp = getLogBook(cache['guid'])
        if newcomments.length > 0
          comments = newcomments
          cache['ltime'] = logtimestamp
        end
      end
    end
    if comments.length > 0
      cache['last_find_type'] = comments[0]['type']
      cache['last_find_days'] = daysAgo(comments[0]['date'])
      if not last_find_date
        last_find_date = comments[0]['date']
      end
      # Remove possibly unpaired font tags (issue 231)
      (0...comments.length).each{ |c|
        comments[c]['text'].gsub!(/<\/?font[^>]*>/, '')
      }
    end
    cache['comments'] = comments

    if (not cache['mdays'] or cache['mdays'] == -1) and last_find_date
      cache['mtime'] = last_find_date
      cache['mdays'] = daysAgo(cache['mtime'])
    end

    if not cache['ctime']
      cache['cdays'] = -1
      cache['ctime'] = Time.at($ZEROTIME)
    end

    # if event is in the past (yesterday or before) it's unavailable
    if cache['event'] and cache['ctime']
      if cache['cdays'] > 0
        debug "Disabling past event cache #{wid.inspect} (#{cache['cdays']} days)"
        cache['disabled'] = true
      end
    end

    # more patchwork for inaccessible stuff
    if not cache['difficulty']
      cache['difficulty'] = 1
    end
    if not cache['terrain']
      cache['terrain'] = 1
    end
    if not cache['size']
      cache['size'] = "not chosen"
    end

    if not cache['last_find_days']
      cache['last_find_days'] = -1
      cache['last_find_type'] = 'none'
    end

    #unused#comment_text = comments.collect{ |x| x['text'] }
    cache['additional_raw'] = parseAdditionalWaypoints(data)

    # Add "map" waypoints (PMO)
    if not cache['additional_raw'] and cache['additional_raw2']
      debug "Insert waypoints from MAP"
      cache['additional_raw'] = cache['additional_raw2']
    end

    # Fix cache owner/name
    if cache['name2'] and cache['creator2']
      if cache['creator2'] != cache['creator']
        debug "Fix cache name and creator: \"#{cache['name2']}\" by \"#{cache['creator2']}\" (was \"#{cache['name']}\" by \"#{cache['creator']}\")"
        cache['creator'] = cache['creator2']
        cache['name'] = cache['name2']
      end
    end

    # should not happen, but we need this field in list output
    if not cache['fulltype']
      cache['fulltype'] = 'Cache type unknown'
    end
    if not cache['type']
      cache['type'] = 'empty'
    end

    # daniel.k.ache: links to gallery images
    # @getimage comes as string or nil
    gi = @getimage.to_i
    if (gi > 0)
      cache['gallery'] = getImageLinks(cache['guid'], cacheimages=((gi & 1) != 0), logimages=((gi & 2) != 0))
      #cache['longdesc'] << '<hr />' + cache['gallery']
    else
      cache['gallery'] = ''
    end

    return cache
  end  # end function

  def removeAlignments(text)
    new_text = text.gsub(/(<div .*?)align=/m, '\1noalign=')
    new_text.gsub!(/(<p .*?)align=/m, '\1noalign=')
    new_text.gsub!('<center>', '')
    if text != new_text
      debug2 "fixed alignments"
    end
    return new_text
  end

  def fixRelativeImageLinks(text)
    new_text = text.gsub(' src="/', ' src="https://www.geocaching.com/')
    if text != new_text
      debug2 "fixed relative links"
    end
    return new_text
  end

  def parseAdditionalWaypoints(text)
    # <p><p><strong>Additional Waypoints</strong></p></p>
    if text =~ /Additional Waypoints.*?(<table.*?\/table>)/m
      additional = $1
      return fixRelativeImageLinks(additional)
    else
      return nil
    end
  end

  def parseMapWaypoints(cmaptext)
    cmaphash = Hash.new()
    cmaptext.split(/},{/).each{ |wp|
      itemhash = Hash.new()
      begin
        # strip curly brackets, be careful when splitting items at commas and colons:
        # {"lat":52.13368,"lng":12.56848,"type":218,"name":"Huhu, wer schaut aus dem Haus raus? ( Question to Answer )","pf":"S6"}
        # were not 100% safe, better have a dummy error handler
        wp.gsub(/^{/, '').gsub(/}$/, '').split(/,\"/).each{ |item|
          keyval = item.split(/\":/)
          itemhash[keyval[0].gsub(/\"/, '')] = keyval[1].gsub(/\\\"/, '*').gsub(/\"/, '')
        }
        if itemhash['pf']
          cmaphash[itemhash['pf']] = itemhash
        end
      rescue # ignore errors
      end
    }
    debug2 "MAP WP all: #{cmaphash.inspect}"
    if cmaphash.empty?
      return nil
    end
    # create table similar to Additional Waypoints and return that
    table = ''
    table << "<table id=\"Waypoints\">\n"
    table << "  <tbody>\n"
    cmaphash.each_key{ |pf|
      cmapitem = cmaphash[pf]
      # convert floats to "X xx&deg; xx.xxx"
      slat = lat2str(cmapitem['lat'], degsign="&#176;")
      slon = lon2str(cmapitem['lng'], degsign="&#176;")
      type = cmapitem['type']
      sym = "Unknown #{type}" # do not know better yet
      case type.to_i
      when 217
        sym = "Parking Area"
      when 218
        sym = "Virtual Stage"
      when 219
        sym = "Physical Stage"
      when 220
        sym = "Final Location"
      when 221
        sym = "Trailhead"
      when 452
        sym = "Reference Point"
      end
      # strip blanks off wpt type in parentheses
      name = cmapitem['name'].gsub(/\(\s*(.*?)\s*\)/){"(#{$1})"}
      table << "    <tr ishidden=\"false\">\n"
      table << "      <td></td>\n"			# col 1: empty
      table << "      <td></td>\n"			# col 2: (visibility icon) empty
      table << "      <td></td>\n"			# col 3: (point type icon) empty
      table << "      <td>#{pf}</td>\n"			# col 4: Prefix
      table << "      <td>#{pf}</td>\n"			# col 5: (Lookup)
      table << "      <td>#{name} (#{sym})</td>\n"	# col 6: Name (type)
      table << "      <td>#{slat} #{slon}</td>\n"	# col 7: Coordinate
      table << "      <td></td>\n"			# col 8: empty
      table << "    </tr>\n"
      table << "    <tr>\n"
      table << "      <td></td>\n"
      table << "      <td>Note:</td>\n"
      table << "      <td></td>\n"
      table << "    </tr>\n"
    }
    table << "  </tbody>\n"
    table << "</table>"
    return table
  end

  def parseComments(data, creator)
    comments = []
    visitors = []
    last_find = nil

    # <dt>
    #   [<img src='http://www.geocaching.com/images/icons/icon_smile.gif' alt="Found it" />&nbsp;Found it]
    # !! new 2012-12-11 !!:
    #   [<img src='../images/logtypes/2.png' alt="Found it" />&nbsp;Found it]
    #   Sunday, 10 October 2010
    #   by <strong>
    #       silvinator</strong> (52
    #   found)
    # </dt>
    # <dd>
    # Gut gefunden. Man sollte nur auf Muggels achten!  Danke!</dd>
    #data.scan(/<dt.*?icon_(\w+).*?alt=\"(.*?)\".*?, ([\w, ]+)\s+by <strong>\s*(.*?)\s*<\/strong>.*?<dd>\s*(.*?)\s*<\/dd>/m){ |icon, type, datestr, user, comment|
    data.scan(/<dt.*?\/([\w]+)\.[^\.]+?\salt=\"(.*?)\".*?, ([\w, ]+)\s+by <strong>\s*(.*?)\s*<\/strong>.*?<dd>\s*(.*?)\s*<\/dd>/m){ |icon, type, datestr, user, comment|
      debug2 "comment date: #{datestr}, icon: #{icon}, type: #{type}, user: #{user}"
      # strip "icon_" from old style image name
      icon.gsub!(/^icon_/, '')
      # parseDate cannot handle this
      #date = parseDate(datestr)
      # use Time.parse, add 12 hours
      date = Time.parse(datestr) + (12 * $HOUR)
      # "found it" or "attended"
      if (icon == 'smile' or icon == '2') or (icon == 'attended' or icon == '10')
        visitors << user.downcase
        if not last_find
          last_find = date.dup
        end
      end
      # we don't need the icon type
      comment = {
        'type' => type,
        'date' => date,
        'user' => user,
        'user_id' => Zlib.crc32(user),
        'text' => comment
      }
      debug3 "COMMENT: #{comment.inspect}"
      comments <<  comment
    }
    return [comments, last_find, visitors]
  end

  def removeSpam(text)
    # <a href="http://s06.flagcounter.com/more/NOk"><img src= "http://s06.flagcounter.com/count/NOk/bg=E2FFC4/txt=000000/border=CCCCCC/columns=4/maxflags=32/viewers=0/labels=1/pageviews=1/" alt="free counters" /></a>
    removed = text.dup
    removed.gsub!(/<a href[^>]*><img src[^>]*((flag|gc)counter|andyhoppe\.com|gcwetterau\.de|gcstat\.selfip|gcvote)[^>]*><\/a>/m, '')
    removed.gsub!(/<a href=[^>]*hitwebcounter.com[^>]*>.*?<\/a[^>]*>/m, '')
    removed.gsub!(/<!--[^>]*hitwebcounter[^>]*-->/m, '')
    if removed != text
      debug2 "Removed spam"
    end
    return removed
  end

  def removeSpan(text)
    # remove <span> tags from HTML
    removed = text.gsub(/<\/?span[^>]*>/m, '')
    if removed != text
      debug2 "Removed span"
    end
    return removed
  end

end
