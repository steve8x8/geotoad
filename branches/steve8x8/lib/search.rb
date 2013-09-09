# $Id$

require 'cgi'
require 'geocode'
require 'shadowget'
require 'time'


class SearchCache
  include Common
  include Messages

  attr_accessor :distance, :max_pages

  @@base_url = 'http://www.geocaching.com/seek/nearest.aspx'

  def initialize
    @distance = 15
    @max_pages = 0		# unlimited
    @ttl = 12 * 3600		# 12 hours (was 20)
    @waypoints = Hash.new

    # cache types for selected search
    @cachetypetx = {
	'traditional'  => '32bc9333-5e52-4957-b0f6-5a2c8fc7b257',
	'multicache'   => 'a5f6d0ad-d2f2-4011-8c14-940a9ebf3c74',
	'virtual'      => '294d4360-ac86-4c83-84dd-8113ef678d7e',
	'letterbox'    => '4bdd8fb2-d7bc-453f-a9c5-968563b15d24',
	'event'        => '69eb8534-b718-4b35-ae3c-a856a55b0874',
	'unknown'      => '40861821-1835-4e11-b666-8d41064d03fe',
    #	'project'      => '2555690d-b2bc-4b55-b5ac-0cb704c0b768',
	'webcam'       => '31d2ae3c-c358-4b5f-8dcd-2185bf472d3d',
	'reverse'      => '8f6dd7bc-ff39-4997-bd2e-225a0d2adf9d',
	'cito'         => '57150806-bc1a-42d6-9cf0-538d171a2d22',
	'earthcache'   => 'c66f5cf3-9523-4549-b8dd-759cd2f18db8',
	'megaevent'    => '69eb8535-b718-4b35-ae3c-a856a55b0874',
	'wherigo'      => '0544fa55-772d-4e5c-96a9-36a51ebcf5c9',
	'lost+found'   => '3ea6533d-bb52-42fe-b2d2-79a3424d4728',
	'gshq'         => '416f2494-dc17-4b6a-9bab-1a29dd292d8c',
	'lfceleb'      => 'af820035-787a-47af-b52b-becc8b0c0c88',
    #	'exhibit'      => '72e69af2-7986-4990-afd9-bc16cbbb4ce3',
    # play safe
	'mystery'      => '40861821-1835-4e11-b666-8d41064d03fe',
	'puzzle'       => '40861821-1835-4e11-b666-8d41064d03fe',
    #	'ape'          => '2555690d-b2bc-4b55-b5ac-0cb704c0b768',
	'locationless' => '8f6dd7bc-ff39-4997-bd2e-225a0d2adf9d'
    }
    @txfilter = nil

    # exclude own found
    @notyetfound = false

    # Original base-42 code taken from Rick Richardson's geo-* utilities
    # @ http://geo.rkkda.com/ (patch of 2011-01-04 19:25 local time),
    # but those only worked until 2011-01-06 (kept here for reference).
    #@base = 42
    # 2011-01-05/06:
    #@code = "hbM9fjmrxy7z42LFD58BkKgPGdHscvCqNnw3ptO6lJ"

    # On 2011-01-07, Steve8x8 found that now a base-57 alphabet was being used
    # with a similar algorithm. The encoding key changes each midnight UTC.
    # To make things worse, any encoding is only valid for a few minutes.
    @base = 57
    # all base-57 alphabets consist of ([0-9a-zA-Z] - [1iIuU])!
    # codes repeat themselves after one month
    @codetable = {
	 1 => "PDMTRXBJjZNH9fKW8vetlCgbos24mydknahrcOxYqLwGSE370z65ApVFQ",
	 2 => "6JKt4b70rHoeTLqQB2jANwcYSMW9xPk3aplE5hGvyfsZDgFmndOVRC8zX",
	 3 => "Rl2QaDdTsnK7rOZoywzx0H58NLCAGqgtp43mvYJVkFEejMWB69cXhfSbP",
	 4 => "jShz6gF3OvonKEWkJCbZf4GeDX25VcyPsqwRYpLM8BtATm0x7l9aHQdNr",
	 5 => "aJs2OWpoYfN9zvDHCwZrm83b4SKkFhXcAL0QPgBy7tMdRGlqxjEVn65Te",
	 6 => "g6aXp7rqvkEl5JLnRDhfWGHTeA9OMQYdwS2BcbK0jCyFx4sPo83tmzZVN",
	 7 => "MlocEO5eAgTFfLXzyPDk2qJhjBn98QSdNHR47mGWtY3ZvVxCpr0Ks6abw",
	 8 => "p7SPbvzM4VkQ8f25cJL0gBlWjYmFoKhArXRHZntTGe6CNsyE3a9qOdwDx",
	 9 => "znlBb8GHNdhCKyOpo53ePX9xfkvjD0aTEAVZ72qSQwrmMYct6JgRFWLs4",
	10 => "KXztRHdrkBwSWEn3AN2Fh8vOL5QMjx6oTgyCD7JYpaGmVcf9Pelb4q0Zs",
	11 => "M3odkDCgQa7GWK9pYh8tLAl6xFecRwPZNbTz0s42rqfOnSmvEjVyB5JXH",
	12 => "gweGxNAYCKfLdrb68X93ahjHMDtTWRFJVZvl0po5ySmOQnscPz4Ekq2B7",
	13 => "p2zelnEox9HqkGF4V5AZ6LbMBsy0dQc8J3fDXvON7jWgrKYCSTaPtRhmw",
	14 => "cy2gjCAJt3KmMxbr5OzQeYsvHpLF8fRVaoNXdGBW0l7ESZDP9qkw4Th6n",
	15 => "9KQZlwfBsCqN6oWkYhrSpDAEP48c5m3eJn2jVHLdybMx0gaOGRXzvFTt7",
	16 => "7j6CJPfqbMygan42HwxFBcrK3RYLstmOXWGeSQZ9kzl0VE8oDTpAhd5Nv",
	17 => "YScWw7gsx49ebLAqMGotHRX3fnCv6FBOkzVE5jdlmPTarDKQJyp8Z0hN2",
	18 => "BgwR6oskAcVPqeYdLKr3ONvflXz2nDSbxMQJEhyZC0pWHm759GFa4tT8j",
	19 => "9QyolrBq37he4nbCTcXEkmGHjYS02RDgMZLfOtavVzKNFxPs58p6JwWAd",
	20 => "8OwsHykXLJ3tqWZmR2pbVagMcTdnSC9FveN5z0xYjGK6frh7Q4EPDBAlo",
	21 => "RVBh8qEaN4Aw2Ob5egSytWjQD6oFmKvXfYnCzcx73kJsHrd9TLPZM0Glp",
	22 => "7MqQGJkKzZvdgmRXBH8CYeAVf3cy29LOW4PNaD0rsnowEpTbF5Sxhtl6j",
	23 => "8C26QBoWjEPcJ3Sf7TYtexXlMNyqArm0KD9HOLvZakGwnVbFsdp45Rzhg",
	24 => "6e5fC2S4Bwcm9pVKyqdFE3WlRDroTLJgGtN8ZQsAabMzHYO0Xvj7Pnxhk",
	25 => "JXHgMGcAVNpDEwWYvyBl025m89dOoTSKPxhstjq6e4QrCk3aZFbzfn7RL",
	26 => "Yp3ARoesjKXB2cadmkHvFQM7SEJtqf0l9TwzbPLrZDxO8h5C6NnGWyVg4",
	27 => "9kJaM4HonPWtcQvsYSEK3Vy5pjCRFqNO6lgr0x7mh2b8wdTGDzfLXeABZ",
	28 => "4n2gSwqzGB7C0MpV3yDY9FTtol8XjkJNcEPr6LxhZQKdRvHOfsA5eWmab",
	29 => "P6G8jsOxBCqf3k74DnXtAvl2ThabeEHJVgZp5wSzF9NWRcYMyL0dromKQ",
	30 => "WVwgM93zjmNcLpHvoSK2Q5bCxaATGsryXn6Bhfd0Z8qtERk7PYOJD4Fle",
	31 => "PZqTVol4HOXz0GWt38Qec59rKMyabfhE2DdsNxpF7RASkBjnYwvCgmJ6L"
    }

    # server uses UTC!
    @code = @codetable[Time.now.utc.day]
    nodebug "D/T/S decoding uses code #{@code}"
  end

  def txfilter=(cacheType)
    # may return nil if not found
    @txfilter = @cachetypetx[cacheType]
    debug "Setting txfilter to \"#{cacheType}\", now #{@txfilter.inspect}"
  end

  def notyetfound=(truefalse)
    @notyetfound = truefalse
  end

  def setType(mode, key)
    @query_type = nil
    @query_arg = key
    supports_distance = false
    case mode
    when 'location'
      @query_type = 'location'
      geocoder = GeoCode.new()
      accuracy, lat, lon = geocoder.lookup_location(key)
      debug "geocoder returned: a:#{accuracy.inspect} x:#{lat} y:#{lon}"
      if not accuracy
        displayWarning "Google Maps failed to determine the location of #{key}"
        return nil
      else
        displayMessage "Google Maps found \"#{key}\". Accuracy level: #{accuracy}"
        displayMessage "Will use coordinates #{lat}, #{lon}"
      end
      lat = sprintf("%2.6f", lat).gsub(/0{1,5}$/, '')
      lon = sprintf("%2.6f", lon).gsub(/0{1,5}$/, '')
      @search_url = @@base_url + "?lat=#{lat}&lng=#{lon}"
      supports_distance = true

    when 'coord'
      @query_type = 'coord'
      supports_distance = true
      lat, lon = parseCoordinates(key)
      lat = sprintf("%2.6f", lat).gsub(/0{1,5}$/, '')
      lon = sprintf("%2.6f", lon).gsub(/0{1,5}$/, '')
      @search_url = @@base_url + "?lat=#{lat}&lng=#{lon}"

    when 'user'
      @query_type = 'ul'
      @ttl = 3 * 24 * 3600	# 3 days (was 12 hours)

    when 'owner'
      @query_type = 'u'
      @ttl = 3 * 24 * 3600	# 3 days

    when 'country'
      @query_type = 'country'
      @search_url = @@base_url + "?country_id=#{key}&as=1"
      @ttl = 14 * 24 * 3600	# 2 weeks

    when 'state'
      @query_type = 'state'
      @search_url = @@base_url + "?state_id=#{key}"
      @ttl = 14 * 24 * 3600	# 2 weeks

    when 'keyword'
      @query_type = 'key'

    when 'wid'
      @query_type = 'wid'
      @query_arg = key.upcase
      @search_url = "http://www.geocaching.com/seek/cache_details.aspx?wp=#{key.upcase}"

    when 'guid'
      @query_type = 'guid'
      @query_arg = key.downcase
      @search_url = "http://www.geocaching.com/seek/cache_details.aspx?guid=#{key.downcase}"
    end

    if not @query_type
      displayWarning "Invalid query type: #{mode}. Valid types include: location, coord, keyword, wid"
      return nil
    end

    if not @search_url
        @search_url = @@base_url + '?' + @query_type + '=' + CGI.escape(@query_arg.to_s)
    end

    if @txfilter
        @search_url = @search_url + '&tx=' + @txfilter
    end

    if @notyetfound
        @search_url = @search_url + '&f=1'
    end

    if supports_distance and @distance
        @search_url = @search_url + '&dist=' + @distance.to_s
    end

    debug @search_url
    return @query_type
  end

  def parseCoordinates(input)
    # kinds of coordinate representations to parse (cf. geo-*):
    #
    #        -93.49130       DegDec (decimal degrees, simple format)
    #        W93.49130       DegDec (decimal degrees)
    #        -93 29.478      MinDec (decimal minutes, caching format)
    #        W93 29.478      MinDec (decimal minutes)
    #        -93 29 25       DMS
    #        W 93 29 25       DMS
    # not yet (":" is separator for input)
    #        -93:29.478      MinDec (decimal minutes, gccalc format)
    #        W93:29.478      MinDec (decimal minutes)
    #
    # we've got two of them separated by whitespace and/or comma!

    # older version of parseCoordinates() returned big array
    # newer version will return latitude and longitude only
    # for a while, both formats will be filled in
    # ToDo: activate proper code path

    # replace NESW by signs, remove extra space, colon/comma by blank
    key = input.upcase.tr(':,', '  ').gsub(/[NE\+]\s*/, '').gsub(/[SW-]\s*/, '-')
    # Both coordinates must have same format. Count number of fields.
    case key.split("\s").length #may be 2, 4, 6
    when 2 # Deg
      if key =~ /(-?)([\d\.]+)\W\W*?(-?)([\d\.]+)/
        lat = $2.to_f
        if $1 == '-'
          lat = -lat
        end
        lon = $4.to_f
        if $3 == '-'
          lon = -lon
        end
      else
        displayError "Cannot parse #{input} as two degree values!"
      end
    when 4 # Deg Min
      if key =~ /(-?)([\d\.]+)\W+([\d\.]+)\W\W*?(-?)([\d\.]+)\W+([\d\.]+)/
        lat = $2.to_f + $3.to_f/60.0
        if $1 == '-'
          lat = -lat
        end
        lon = $5.to_f + $6.to_f/60.0
        if $4 == '-'
          lon = -lon
        end
      else
        displayError "Cannot parse #{input} as two degree/minute values!"
      end
    when 6 # Deg Min Sec
      if key =~ /(-?)([\d\.]+)\W+([\d\.]+)\W+([\d\.]+)\W\W*?(-?)([\d\.]+)\W+([\d\.]+)\W+([\d\.]+)/
        lat = $2.to_f + $3.to_f/60.0 + $4.to_f/3600.0
        if $1 == '-'
          lat = -lat
        end
        lon = $6.to_f + $7.to_f/60.0 + $8.to_f/3600.0
        if $5 == '-'
          lon = -lon
        end
      else
        displayError "Cannot parse #{input} as two degree/minute/second values!"
      end
    else
      # did not recognize format
      displayError "Bad format in #{input}: #{key.split("\s").length} fields found."
    end
    # sub-meter precision
    lat = sprintf("%.7f", lat)
    lon = sprintf("%.7f", lon)
    displayMessage "Coordinates \"#{input}\" parsed as latitude #{lat}, longitude #{lon}"
    return lat, lon
  end

  def decodeDTS(v)
    debug "Invoking decodeDTS with \"#{v}\""

    # get current decoding alphabet from list
    base = @base
    code = @code

    text = v
    # base(base) to numeric
    value = 0
    (0...text.length).each { |index|
      digit =  (code =~ /#{text[index,1]}/)
      if not digit
        # serious error: we're pretty sure to know the character set
        debug "Cannot interpret \"#{text[index,1]}\", setting to 0"
        digit = 0
      end
      value = base * value + digit
    }
    debug "Converted #{text}(#{base}) to #{value}"

    if base == 42
      # old code that worked only two days, kept here for reference
      mod = (value - 131586) % 16777216
      # cache size
      s0 = (mod / (base * base * base)).to_i
      s = ["not chosen", "micro", nil, "regular", nil, "large", nil, "virtual",
           "unknown", nil, nil, nil, "small"][s0]
      diff = [0, 1, nil, 2, nil, 3, nil, 4,
              5, nil, nil, nil, 7][s0]
      if diff
        diff *= 131072
      else
        diff = -1
      end
      # terrain, difficulty
      t0 = ((mod - diff) / (6 * 42)).to_i
      d0 = (((mod - diff) % 42) - (t0 * 4)).to_i
      t = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5][t0]
      d = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5][d0]
      # s, d, t may be nil
    elsif base == 57
      #
      # value = 2^24*M + 2^17*S + 2^8*T + 2^0*D + (2^17 + 2^9 + 2^1)
      # M = 60 - minute
      # S = encoded container size (as in cache edit, but +1)
      # T = (terrain-1)*2
      # D = (difficulty-1)*2
      #
      # example: GC11Z19, D/T 2.5/2.5 small, full hour, 2011-01-14:
      # -> M=60, S=7, T=3, D=3 -> 1007682821(10) -> 01,38,26,14,38,56(57)
      # -> "yBLbBn"
      #
      mod = (value - 131586) % 16777216
      s0 = (mod / 131072).to_i
      s = ["not chosen", "micro", "regular", "large",
           "virtual", "other", nil, "small"][s0]
      t0 = ((mod % 131072) / 256).to_i
      d0 = ((mod % 131072) % 256).to_i
      # terrain rating, may return nil
      t = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5][t0]
      d = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5][d0]
      # deliberately not setting defaults if nil
    end
    debug "Using preD/T/S=#{d0}/#{t0}/#{s0}, return D/T/S=#{d}/#{t}/#{s}"
    return d, t, s, "#{value}=#{d}/#{t}/#{s}"
    #return d, t, s, value
  end

  def decodeDD(v)
    debug "Invoking decodeDD with \"#{v}\""
    # the xor pattern is "signalthefrog"
    xorpattern = ["73", "69", "67", "6e", "61", "6c", "74", "68",
                  "65", "66", "72", "6f", "67", "73", "69", "67"]
    directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
    text = v.dup
    # replace %xy codes with their "real" values
    text.gsub!(/%([0-9a-fA-F][0-9a-fA-F])/) { $1.to_i(16).chr }
    textlen = text.length
    if textlen > 16
      textlen = 16
    end
    # unfortunately there's no native xor for strings
    encoded = text.unpack("c" * textlen)
    decoded = []
    textlen.times { |index|
      decoded[index] = (encoded[index] ^ xorpattern[index].hex).chr
    }
    dd = decoded.join.split("|")
    distance = dd[0]
    # special case: "Here" in various languages: we hit a cache location
    if distance !~ /\d ft$/ and distance !~ /\d mi$/ and distance !~ /\d km$/
      distance = "0.0"
    end
    # direction "rounding"
    direction = directions[((dd[1].to_f+22.5)/45.0).to_i]
    # anyone interested in precise azimuth?
    #direction << "(#{dd[1]})"
    debug "Returning from decodeDD: \"#{distance}@#{direction}\""
    return [distance, direction]
  end

  def getResults()
    nodebug "Getting results: #{@query_type} at #{@search_url}"
    if @query_type == 'wid'
      waypoint = getWidSearchResult(@search_url)
      if ! waypoint
        # no valid page found
        return {}
      end
      wid = waypoint['wid']
      if wid
        if (wid != @query_arg)
          displayWarning "Replacing WID #{@query_arg} with #{wid}"
          @query_arg = wid
        end
        @waypoints[@query_arg] = waypoint
      end
      return @waypoints
    elsif @query_type == 'guid'
      waypoint = getWidSearchResult(@search_url)
      if ! waypoint
        # no valid page found
        return {}
      end
      wid = waypoint['wid']
      # did we find a WID?
      if wid
        waypoint['guid'] = @query_arg
        @waypoints[wid] = waypoint
      else
        displayWarning "Could not find WID for GUID #{@query_arg}"
      end
      return @waypoints
    else
      return searchResults(@search_url)
    end
  end

  def getWidSearchResult(url)
    data = getPage(@search_url, {})
    if not data
      displayError "No data to be analyzed! Check network connection!"
    end
    guid = nil
    wid = nil
    disabled = false
    archived = false
    membersonly = false
    country = nil
    state = nil
    ctype = 'Unknown Cache'
    owner = nil
    cname = nil
    csize = nil
    cdiff = nil
    cterr = nil
    ctime = Time.at($ZEROTIME)
    cdays = -1
    begin
    if data =~ /<title>\s*404 - File Not Found\s*<\/title>/m
      debug "Unknown cache, error 404"
      return nil
    end
    data.split("\n").each { |line|
      line.gsub!(/&#39;/, '\'')
      case line
      when /Geocaching . Hide and Seek a Geocache . Unpublished Geocache/
        debug "Unpublished cache, leaving parser"
        break
      when /Premium Member Only Cache/
        membersonly = true
      when /^\s+GC.*\((.*)\) in ((.*), )?(.*) created by (.*?)\s*$/
        ctype = $1
        state = $3
        country = $4
        owner = $5
        debug "#{ctype} by #{owner} in #{country}/#{state}"
      #<span id="ctl00_ContentBody_MapLinks_MapLinks">...
      #...<li><a href="http://maps.google.com/maps?q=N+12%c2%b0+46.880+E+100%c2%b0+54.304+(GC10011)+" target="_blank">Google Maps</a></li>...
      #...<li><a href="http://www.bing.com/maps/default.aspx?v=2&lvl=14&sp=point.12.78133_100.90507_GC10011" target="_blank">Bing Maps</a></li>...
      # not sure whether Google Maps links will disappear completely, let's have Bing in place
      # Caveat: GC wid codes may be absent (for Premium Members?)
      when /\+\((GC\w+)\)\+[^>]+>Google Maps/
        wid = $1
        debug "Found WID: #{wid} (Google)"
      when /_(GC\w+)[^>]+>Bing Maps/
        wid = $1
        debug "Found WID: #{wid} (Bing)"
      when /\<meta name=.og:url.\s+content=.http:\/\/coord.info\/(GC\w+)./
        wid = $1
        debug "Found WID: #{wid} (coord.info)"
      # added 2012-05-15:
      #<span id="ctl00_ContentBody_CoordInfoLinkControl1_uxCoordInfoCode" class="CoordInfoCode">GCZFC2</span>
      when /class=.CoordInfoCode.\>(GC\w+)\<\/span\>/
        wid = $1
        debug "Found WID: #{wid} (CoordInfo)"
      #<input type="submit" name="ctl00$ContentBody$btnSendToPhone" value="Send to My Phone" onclick="s2phone(&#39;GC332MT&#39;);return false;" id="ctl00_ContentBody_btnSendToPhone" />
      when /onclick=.s2phone\(.*?(GC\w+).*?\);return/
        wid = $1
        debug "Found WID: #{wid} (s2phone)"
      # for filtering; don't care about ".0" representation
      when /_uxLegendScale.*?(\d(\.\d)?) out of/
        cdiff = tohalfint($1)
        debug "Found D: #{cdiff}"
      when /_Localize12.*?(\d(\.\d)?) out of/
        cterr = tohalfint($1)
        debug "Found T: #{cterr}"
      when /alt=.Size: .*\((.*?)\)/
        csize = $1.downcase
        debug "Found size: #{csize}"
      when /_CacheName.\>(.*?)\<\/span\>/
        cname = $1
        debug "Found cache name: #{cname.inspect}"
      when /\s*A cache by \<a[^\>]*\>(.*?)\<\/a/
        owner = $1
        debug "Found owner: #{owner.inspect}"
      end
    }
    rescue => error
      displayWarning "Error in getWidSearchResult():data.split"
      if data =~ /(\+\(|_|CoordInfoCode.\>)(GC\w+)(\)\+[^>]+>Google Maps|[^>]+>Bing Maps|\<\/span\>)/
        displayWarning "WID affected: #{$2}"
      end
      raise error
    end
    # creation/event date
    #                 <div id="ctl00_ContentBody_mcd2">
    #                Hidden:
    #                10/11/2011
    if data =~ /<div[^>]*mcd2.>\s*[\w ]*:\s*((\d+ \w{3} \d+)|([0-9\/\.-]+))/m
      debug "Found creation date: #{$1}"
      ctime = parseDate($1)
      cdays = daysAgo(ctime)
    end
    # one match is enough!
    if data =~ /cdpf\.aspx\?guid=([\w-]+)/m
      guid = $1
      debug "Found GUID: #{guid}"
    end
    if data =~ /Cache Issues:.*class=.OldWarning..*This cache is temporarily unavailable/
      disabled = true
      debug "Cache appears to be disabled"
    end
    if data =~ /Warning.*This cache listing has been archived/
      archived = true
      debug "Cache appears to be archived"
    end
    if data =~ /Cache Issues:.*class=.OldWarning..*This cache has been archived/
      archived = true
      debug "Cache appears to be archived"
    end

    cache_data = {
      'guid' => guid,
      'wid' => wid,
      'disabled' => disabled,
      'archived' => archived,
      'membersonly' => membersonly,
      'country' => country,
      'state' => state,
      'name' => cname,
      'creator' => owner,
      'fulltype' => ctype,
      'type' => ctype.to_s.split(' ')[0].downcase.gsub(/\-/, ''),
      'size' => csize.to_s.gsub(/medium/, 'regular'),
      'difficulty' => cdiff,
      'terrain' => cterr,
      # these are educated guesses only
      'ctime' => ctime,
      'cdays' => cdays,
      'atime' => Time.at($ZEROTIME),
      'mtime' => Time.at($ZEROTIME),
      'visitors' => []
    }
    return cache_data
  end

  def searchResults(url)
    debug "searchResults: #{url}"
    if not url
      displayWarning "searchResults has no URL?"
    end
    post_vars = Hash.new

    page_number, pages_total, parsed_total, post_vars, src = processPage({})
    progress = ProgressBar.new(1, pages_total, "Processing results for #{@query_arg}")
    progress.updateText(page_number, "from #{src}")
    if not parsed_total or parsed_total == 0
      displayMessage "No geocaches were found."
      return @waypoints
    end

    if not page_number
      displayWarning "Could not determine current page number from #{url}"
      displayError   "Please set language to English on GC.com as a workaround."
      return @waypoints
    end

    if not pages_total
      displayWarning "Could not determine total pages from #{url}"
      displayError   "Please set language to English on GC.com as a workaround."
      return @waypoints
    end

    # special case: only first page
    if @max_pages == 1
      debug "Limiting to first search page"
      return @waypoints
    end

    while (page_number < pages_total)
      debug "*** On page #{page_number} of #{pages_total}"
      last_page_number = page_number
      page_number, total_pages, total_waypoints, post_vars, src = processPage(post_vars)
      debug "processPage returns #{page_number}/#{total_pages}"
      progress.updateText(page_number, "from #{src}")

      if page_number == last_page_number
        displayError "Stuck on page number #{page_number} of #{total_pages}"
      elsif page_number < last_page_number
        displayError "We were on page #{last_page_number}, but just read #{page_number}. Parsing error?"
      end
      # limit search page count
      if ! ((@max_pages == 0) or (page_number < @max_pages))
        debug "Reached page count limit #{page_number}/#{@max_pages}"
        page_number = pages_total
      end
    end
    return @waypoints
  end

  def getPage(url, post_vars)
    page = ShadowFetch.new(url)
    if $DTSFILTER
      # DTS decoding: drop search pages from yesterday UTC
      sincemidnight = 60*( 60*Time.now.utc.hour + Time.now.utc.min )
      # correct TTL only if no user search!
      if (sincemidnight < @ttl) and (url !~ /nearest.aspx.ul=/)
        @ttl = sincemidnight
      end
    end
    page.localExpiry = @ttl
    if (post_vars.length > 0)
      page.postVars=post_vars.dup
    end

    if (page.fetch)
      return page.data
    else
      return nil
    end
  end

  def processPage(post_vars)
    data = getPage(@search_url, post_vars)
    page_number, pages_total, parsed_total, post_vars = parseSearchData(data)
    cache_check = ShadowFetch.new(@url)
    src = cache_check.src
    return [page_number, pages_total, parsed_total, post_vars, src]
  end


  def parseSearchData(data)
    if not data
      displayError "No data to be analyzed! Check network connection!"
    end
    page_number = nil
    pages_total = nil
    parsed_total = 0
    wid = nil
    waypoints_total = nil
    post_vars = Hash.new
    cache = {
      'disabled' => nil,
      'archived' => nil,
      'membersonly' => false
    }
    # list of US states, generated from seek page
    usstates = {
      "Alabama" => 60,
      "Alaska" => 2,
      "Arizona" => 3,
      "Arkansas" => 4,
      "California" => 5,
      "Colorado" => 6,
      "Connecticut" => 7,
      "Delaware" => 9,
      "District of Columbia" => 8,
      "Florida" => 10,
      "Georgia" => 11,
      "Hawaii" => 12,
      "Idaho" => 13,
      "Illinois" => 14,
      "Indiana" => 15,
      "Iowa" => 16,
      "Kansas" => 17,
      "Kentucky" => 18,
      "Louisiana" => 19,
      "Maine" => 20,
      "Maryland" => 21,
      "Massachusetts" => 22,
      "Michigan" => 23,
      "Minnesota" => 24,
      "Mississippi" => 25,
      "Missouri" => 26,
      "Montana" => 27,
      "Nebraska" => 28,
      "Nevada" => 29,
      "New Hampshire" => 30,
      "New Jersey" => 31,
      "New Mexico" => 32,
      "New York" => 33,
      "North Carolina" => 34,
      "North Dakota" => 35,
      "Ohio" => 36,
      "Oklahoma" => 37,
      "Oregon" => 38,
      "Pennsylvania" => 39,
      "Rhode Island" => 40,
      "South Carolina" => 41,
      "South Dakota" => 42,
      "Tennessee" => 43,
      "Texas" => 44,
      "Utah" => 45,
      "Vermont" => 46,
      "Virginia" => 47,
      "Washington" => 48,
      "West Virginia" => 49,
      "Wisconsin" => 50,
      "Wyoming" => 51,
    }

    inresultstable = false
    begin
    data.split("\n").each { |line|
      # GC change 2010-11-09
      line.gsub!(/&#39;/, '\'')

      # stuff outside results table
      case line
      # <td class="PageBuilderWidget"><span>Total Records: <b>718</b> - Page: <b>23</b> of <b>36</b>&nbsp;-&nbsp;</span>
      # pt: <td class="PageBuilderWidget"><span>Total de Registos:: <b>7976</b> - Página: <b>1</b> de <b>399</b>&nbsp;-&nbsp;</span>
      when /PageBuilderWidget[^:]+:+ +\<b\>(\d+)\<\/b\> [^:]+: +\<b\>(\d+)\<\/b\>.*?\<b\>(\d+)\<\/b\>/
        if not waypoints_total
          waypoints_total = $1.to_i
          page_number = $2.to_i
          pages_total = $3.to_i
        end
        # href="javascript:__doPostBack('ctl00$ContentBody$pgrTop$ctl08','')"><b>Next &gt;</b></a></td>
        if line =~ /doPostBack\(\'([\w\$]+)\',\'\'\)\"\>\<b\>[^\>]+ \&gt;\<\/b\>/ #Next
          debug "Found next target: #{$1}"
          post_vars['__EVENTTARGET'] = $1
        end
      # at least Dutch is different...
      when /doPostBack\(\'([\w\$]+)\',\'\'\)\"\>\<b\>[^\>]+ \&gt;\<\/b\>/ #Next
        debug "Found next target: #{$1}"
        post_vars['__EVENTTARGET'] = $1
      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\" \/\>/
        debug "found hidden post variable: #{$1}"
        post_vars[$1]=$2
      # GC change 2012-02-14
      # <table class="SearchResultsTable Table"> (search results) </table>
      when /\<table class=.SearchResultsTable/
        inresultstable = true
      when /\<\/table\>/
        inresultstable = false
      end #case

      # short-cut if not inside results table
      if not inresultstable
        next
      end

      # stuff strictly inside results table
      case line
      # new travelbug list 2010-12-22
      # single:
      # <a id="ctl00_ContentBody_dlResults_ctl01_uxTravelBugList" class="tblist" data-tbcount="1" data-id="1763522" data-guid="ecfd0038-8e51-4ac8-a073-1aebe7c10cbc" href="javascript:void();"><img src="http://www.geocaching.com/images/wpttypes/sm/21.gif" alt="Travel Bug Dog Tag" title="Travel Bug Dog Tag" /></a>
      # multiple:
      # <a id="ctl00_ContentBody_dlResults_ctl06_uxTravelBugList" class="tblist" data-tbcount="3" data-id="1622703" data-guid="8fc9f301-99fe-4933-90f7-48617e446058" href="javascript:void();"><img src="/images/WptTypes/sm/tb_coin.gif" /></a>
      # this is better handled in cdpf parsing (details.rb)
      # but we need an entry for filtering!
      when /uxTravelBugList/
        debug "trackables flagged: #{line}"
        if line =~ /data-tbcount=\"(\d+)\"/
          cache['travelbug'] = "#{$1} Trackables"
        else
          cache['travelbug'] = "Unspecified Trackable"
        end

# 2011-05-04: unchanged
      #                             11 Jul 10<br />
      # Yesterday<strong>*</strong><br />
      #when /^ +((\w+[ \w]+)|([0-9\/\.-]+))(\<strong\>)?(\*)?(\<\/strong\>)?\<br/
      when /^ +(\w.*?)(\<strong\>)?(\*)?(\<\/strong\>)?\<br/
        debug "last found date: #{$1}#{$3} at line: #{line}"
        cache['mtime'] = parseDate($1+$3.to_s)
        cache['mdays'] = daysAgo(cache['mtime'])
        debug "mtime=#{cache['mtime']} mdays=#{cache['mdays']}"

# 2011-06-15: found date (only when logged in)
      # found date:
      # <span id="ctl00_ContentBody_dlResults_ctl??_uxUserLogDate" class="Success">5 days ago</span></span>
      # <span id="ctl00_ContentBody_dlResults_ctl01_uxUserLogDate" class="Success">Today<strong>*</strong></span></span>
      #when /^ +\<span [^\>]*UserLogDate[^\>]*\>((\w+[ \w]+)|([0-9\/\.-]+))(\<strong\>)?(\*?)(\<\/strong\>)?\<\/span\>\<\/span\>/
      when /^ +\<span [^\>]*UserLogDate[^\>]*\>(.*?)(\<strong\>)?(\*?)(\<\/strong\>)?\<\/span\>\<\/span\>/
        debug "user found date: #{$1}#{$3} at line: #{line}"
        cache['atime'] = parseDate($1+$3.to_s)
        cache['adays'] = daysAgo(cache['atime'])
        debug "atime=#{cache['atime']} adays=#{cache['adays']}"

# 2011-05-04: appended </span>
      # creation date: date alone on line
      #  9 Sep 06</span>
      # may have a "New!" flag next to it
      #  6 Dec 10 <img src="[...]" alt="New!" title="New!" /></span>
# 2013-01-07: now use
      # <span class="small">02/16/2011</span>
      # <span class="small">04/26/2013</span> <span class="Recent">New!</span>
      when /^\s+(<span[^>]*>\s*)?((\d+ \w{3} \d+)|([0-9\/\.-]+))(\s+\<img [^\>]* title="New!" \/\>)?<\/span>\s?(<span[^>]*>New!<\/span>)?\s*$/
        debug "create date: #{$2} at line: #{line}"
        cache['ctime'] = parseDate($2)
        cache['cdays'] = daysAgo(cache['ctime'])
        debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"

# 2011-05-04: unchanged
      # 2010-12-22:
      # <img id="ctl00_ContentBody_dlResults_ctl??_uxDistanceAndHeading" ... \
      #  <src="../ImgGen/seek/CacheDir.ashx?k=..." ...>
      when /CacheDir.ashx\?k=([^\"]*)/
        code = $1
        debug "found CacheDir=#{code.inspect}"
        dist, dir = decodeDD(code)
        # distance is in miles, traditionally
        if (dist =~ /km/)
          dist = dist.to_f / $MILE2KM
        elsif (dist =~ /ft/)
          # 1 mile = 1760 yards = 5280 feet
          dist = dist.to_f / 5280.0
        else
          dist = dist.to_f
        end
        cache['distance'] = dist
        cache['direction'] = dir

# 2013-05-07: back to the roots
      # <span class="small NoWrap"><img src="/images/icons/compass/S.gif" alt="S" title="S" />S<br />0.1mi</span>
      # <span class="small NoWrap"><br />Here</span>
      when /<span.*?\/compass\/.*?>([NWSE]+)<br \/>([\d\.]+)(mi|ft|km)</
        dir = $1
        dist = $2.to_f
        unit = $3
        if (unit =~ /km/)
          dist = dist / $MILE2KM
        elsif (unit =~ /ft/)
          # 1 mile = 1760 yards = 5280 feet
          dist = dist / 5280.0
        end
        cache['distance'] = dist
        cache['direction'] = dir
      when /<span[^>]*><br \/>(\w+)<\/span>/
        cache['distance'] = 0.0
        cache['direction'] = 'N'

# 2011-05-04: unchanged
      # 2010-12-22:
      # <span id="ctl00_ContentBody_dlResults_ctl01_uxFavoritesValue" title="0" class="favorite-rank">0</span>
      when /_uxFavoritesValue[^\>]*\>(\d+)\</
        favs = $1.to_i
        debug "found Favorites=#{favs}"
        cache['favorites'] = favs

# 2011-05-04: unchanged
      # <a href="/seek/cache_details.aspx?guid=c9f28e67-5f18-45c0-90ee-76ec8c57452f">Yasaka-Shrine@Zerosen</a>
      # now (2010-12-22, one line!):
      # <a href="/seek/cache_details.aspx?guid=ecfd0038-8e51-4ac8-a073-1aebe7c10cbc" class="lnk">
      # ...<img src="http://www.geocaching.com/images/wpttypes/sm/3.gif" alt="Multi-cache" title="Multi-cache" /></a>
      # ... <a href="/seek/cache_details.aspx?guid=ecfd0038-8e51-4ac8-a073-1aebe7c10cbc" class="lnk  Strike"><span>Besinnungsweg</span></a>
      #when /cache_details.aspx\?guid=([0-9a-f-]*)[^\>]*>(.*?)\<\/a\>/
      when /(<img[^\>]*alt=\"(.*?)\".*)?cache_details.aspx\?guid=([0-9a-f-]*)([^\>]*)>\<span\>(.*?)\<\/span\>\<\/a\>/
        debug "found type=#{$2} guid=#{$3} name=#{$5}"
        cache['guid'] = $3
        strike = $4
        name = $5
      # type is also in here!
        full_type = $2
        # there may be more than 1 match, don't overwrite
        if cache['fulltype']
          debug "Not overwriting \"#{cache['fulltype']}\"(#{cache['type']} with \"#{full_type}\""
        else
          cache['fulltype'] = full_type
          cache['type'] = full_type.split(' ')[0].downcase.gsub(/\-/, '')
          # special cases
          case full_type
          when /Cache In Trash Out/
            cache['type'] = 'cito'
          when /Lost and Found Celebration/
            cache['type'] = 'lfceleb'
          when /Lost and Found/
            cache['type'] = 'lost+found'
          when /Project APE Cache/
            cache['type'] = 'ape'
          when /Groundspeak HQ/
            cache['type'] = 'gshq'
          when /Locationless/
            cache['type'] = 'reverse'
          when /Block Party/
            cache['type'] = 'block'
          # planned transition
          when /Mystery/
            cache['fulltype'] = 'Unknown Cache'
            cache['type'] = 'unknown'
          end
          if full_type =~ /Event/
            debug "Setting event flag for #{full_type}"
            cache['event'] = true
          end
          debug "short type=#{cache['type']} for #{full_type}"
        end
        debug "Found cache details link for #{name}"

        # AFAIK only "user" queries actually return archived caches
        # class="lnk OldWarning Strike Strike"><span>Lars vom Mars</span></a>
        # class="lnk  Strike"><span>Rund um den See, # 04</span></a>
        if strike =~ /class=\"[^\"]*Warning/
          cache['archived'] = true
          debug "#{name} appears to be archived"
        else
          cache['archived'] = false
        end

        if strike =~ /class=\"[^\"]*Strike/
          cache['disabled'] = true
          debug "#{name} appears to be disabled"
        else
          cache['disabled'] = false
        end

        cache['name'] = name.gsub(/ *$/, '').gsub(/  */, ' ')
        debug "guid=#{cache['guid']} name=#{cache['name']} (disabled=#{cache['disabled']}, archived=#{cache['archived']})"

# 2011-05-04: unchanged
      # by gonsuke@Zerosen and Bakatono@Zerosen
      when /^ +by (.*?)$/
        creator = $1
        cache['creator'] = creator.gsub(/\s+$/, '')
        debug "creator=#{cache['creator']}"

# 2011-05-04: new pattern (try to improve!)
      # | GCabcde | (over multiple lines!)
      when /^ +(GC[0-9A-HJKMNPQRTV-Z]+)\s?$/
	wid = $1
	debug "wid=#{wid}"

# 2011-05-04: appended </span>
      # country/state: prefixed by 28 blanks
      # Mecklenburg-Vorpommern, Germany
      # East Midlands, United Kingdom
      # Comunidad Valenciana, Spain
      # North Carolina (!)
      # also valid (country only):
      # Croatia; Isle of Man; Bosnia and Herzegovina, St. Martin, Guinea-Bissau; Cocos (Keeling) Islands
      # country names: English spelling; state names: local spelling
      #             |>$2|    |->$3 -------------------------------|
      when /^\s{28}((.*?), )?([A-Z][a-z]+\.?([ -]\(?[A-Za-z]+\)?)*)<\/span>\s?$/
        debug "Country/state found #{$2} #{$3}"
        if ($3 != "Icons" && $3 != "Placed" && $3 != "Description" && $3 != "Last Found")
          # special case US states:
          if (usstates[$3])
            cache['country'] = 'United States'
            cache['state'] = $3
          else
            cache['country'] = $3
            cache['state'] = ($2)?$2:'-' # GCStatistic doesn't like empty state elements
          end
          debug "Using country #{cache['country']} state #{cache['state']}"
        end

      # small_profile.gif" alt="Premium Member Only Cache" with="15" height="13"></TD
      when /Premium Member Only Cache/
        debug "#{wid} is a members only cache. Marking"
        cache['membersonly'] = true

# 2011-05-04: unchanged
      # 2010-12-22:
      # <img id="ctl00_ContentBody_dlResults_ctl??_uxDTCacheTypeImage" src="../ImgGen/seek/CacheInfo.ashx?v=MwlMg9" border="0">
      when /CacheInfo.ashx\?v=([a-zA-Z0-9]*)/
        code = $1
        debug "found DTCacheTypeImage #{code}"
        # decode into 'difficulty', 'terrain', 'size'
        cache['dts'] = code # testing only
        d, t, s, v = decodeDTS(code)
        cache['difficulty'] = d
        cache['terrain'] = t
        cache['size'] = s
        cache['dtsv'] = v

# 2013-05-07: back to the roots
      # <span class="small">1.5/1.5</span><br /><img src="/images/icons/container/micro.gif" alt="Size: Micro" title="Size: Micro" />
      when /^\s+<span[^>]*>([\d.]+)\/([\d.]+)<.*?\/container\/(\w+)\./
        cache['difficulty'] = tohalfint($1)
        cache['terrain'] = tohalfint($2)
        cache['size'] = $3.gsub(/_/, ' ') # "not chosen"
        cache['dtsv'] = 'not_encoded'
        cache['dts'] = ''

# 2013-08-21: /geocache/${wid}[_.*] links to new pages
      # <a href="http://www.geocaching.com/geocache/GC42CGC_platz-der-einheit" ...
      when /href=..*\/geocache\/(GC[A-Z0-9]*)_.*/
        if @widsonly
          wid = $1
          debug "found link to WID #{wid}"
        end

      when /^\s+<\/tr\>/
        debug "--- end of row ---"
        if wid and not @waypoints.has_key?(wid)
          debug "- closing #{wid} record -"
          parsed_total += 1
          if not cache['mtime']
            cache['mdays'] = -1
            cache['mtime'] = Time.at($ZEROTIME)
          end
          if not cache['atime']
            cache['adays'] = -1
            cache['atime'] = Time.at($ZEROTIME)
          end

          @waypoints[wid] = cache.dup
          @waypoints[wid]['visitors'] = []

          # if our search is for caches that have been done by a particular user, add to the hash
          if @query_type == "users"
            @waypoints[wid]['visitors'].push(@key.downcase)
          end

          # cache counter (1..n) - need that to reconstruct search order
          @waypoints[wid]['index'] = @waypoints.length
        end
        # clear cache even if there's no wid (yet)
        cache.clear

      end # end case
    } # end loop
    rescue => error
      displayWarning "Error in parseSearchData():data.split"
      raise error
    end
    debug "processPage done: page:#{page_number} total_pages: #{pages_total} parsed: #{parsed_total}"
    return [page_number, pages_total, parsed_total, post_vars]
  end #end parsecache
end
