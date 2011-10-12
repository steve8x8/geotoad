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
    debug "D/T/S decoding uses code #{@code}"
  end

  def setType(mode, key)
    @query_type = nil
    @query_arg = key
    supports_distance = false
    case mode
    when 'location'
      @query_type = 'location'
      @query_arg = key
      geocoder = GeoCode.new()
      accuracy, lat, lon = geocoder.lookup_location(key)
      debug "geocoder returned: a:#{accuracy} x:#{lat} y:#{lon}"
      if not accuracy
        displayWarning "Google Maps failed to determine the location of #{key}"
        return nil
      else
        displayMessage "Google Maps found \"#{key}\". Accuracy level: #{accuracy}"
      end
      @search_url = @@base_url + "?lat=#{lat}&lng=#{lon}"
      supports_distance = true

    when 'coord'
      @query_type = 'coord'
      supports_distance = true
      lat, lon = parseCoordinates(key)
      @search_url = @@base_url + "?lat=#{lat}&lng=#{lon}"

    when 'user'
      @query_type = 'ul'
      @ttl = 24 * 3600		# 1 day (was 12 hours)

    when 'owner'
      @query_type = 'u'
      @ttl = 3 * 24 * 3600	# 3 days

    when 'country'
      @query_type = 'country'
      @search_url = @@base_url + "?country_id=#{key}"
      @ttl = 14 * 24 * 3600	# 2 weeks

    when 'state'
      @query_type = 'state'
      @search_url = @@base_url + "?state_id=#{key}"
      @ttl = 14 * 24 * 3600	# 2 weeks

    when 'keyword'
      @query_type = 'key'

    when 'wid'
      @query_type = 'wid'
      @search_url = "http://www.geocaching.com/seek/cache_details.aspx?wp=#{key.upcase}"
    end

    if not @query_type
      displayWarning "Invalid query type: #{mode}. Valid types include: location, coord, keyword, wid"
      return nil
    end

    if not @search_url
        @search_url = @@base_url + '?' + @query_type + '=' + CGI.escape(@query_arg.to_s)
    end

    if supports_distance and @distance
        @search_url = @search_url + '&dist=' + @distance.to_s
    end

    displayInfo @search_url
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
      #debug "#{index} #{digit} -> #{value}\n"
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
    # special case: we hit a cache location
    if distance =~ /^Here/
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
    debug "Getting results: #{@query_type} at #{@search_url}"
    if @query_type == 'wid'
      waypoint = getWidSearchResult(@search_url)
      wid = waypoint['wid']
      if wid and (wid != @query_arg)
        displayWarning "Replacing WID #{@query_arg} with #{wid}"
        @query_arg = wid
      end
      @waypoints[@query_arg] = waypoint
      return @waypoints
    else
      return searchResults(@search_url)
    end
  end

  def getWidSearchResult(url)
    data = getPage(@search_url, {})
    guid = nil
    if data =~ /cdpf\.aspx\?guid=([\w-]+)/m
      guid = $1
      debug "Found GUID: #{guid}"
    end
    wid = nil
    if data =~ /class=.GCCode.\>(GC\w+)\</m
      wid = $1
      debug "Found WID: #{wid}"
    end
    disabled = false
    if data =~ /Cache Issues:.*class=.OldWarning..*This cache is temporarily unavailable/
      disabled = true
      debug "Cache appears to be disabled"
    end
    archived = false
    if data =~ /Cache Issues:.*class=.OldWarning..*This cache has been archived/
      archived = true
      debug "Cache appears to be archived"
    end
    membersonly = false
    country = nil
    state = nil
    data.split("\n").each { |line|
      line.gsub!(/&#39;/, '\'')
      case line
      when /Premium Member Only Cache/
        membersonly = true
      when /\s+GC.*\(.*\) in ((.*), )?(.*) created by (.*)/
        country = $3
        state = $2
      end
    }

    cache_data = {
      'guid' => guid,
      'wid' => wid,
      'disabled' => disabled,
      'archived' => archived,
      'membersonly' => membersonly,
      'country' => country,
      'state' => state
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
      displayError "Could not determine current page number from #{url}"
      return @waypoints
    end

    if not pages_total
      displayError "Could not determine total pages from #{url}"
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
      if (src == "remote")
        debug "sleeping"
        sleep($SLEEP)
      end

      if page_number == last_page_number
        displayError "Stuck on page number #{page_number} of #{total_pages}"
      elsif page_number < last_page_number
        displayError "We were on page #{last_page_number}, but just read #{page_number}. Parsing error?"
      end
      # limit search page count
      if not ((@max_pages == 0) or (page_number < @max_pages))
        debug "Reached page count limit #{page_number}/#{@max_pages}"
        page_number = pages_total
      end
    end
    return @waypoints
  end

  def getPage(url, post_vars)
    page = ShadowFetch.new(url)
    # DTS decoding: drop search pages from yesterday UTC
    sincemidnight = 60*( 60*Time.now.utc.hour + Time.now.utc.min )
    # correct TTL only if no user search!
    if (sincemidnight < @ttl) and (url !~ /nearest.aspx.ul=/)
      @ttl = sincemidnight
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

    data.split("\n").each { |line|
      # GC change 2010-11-09
      line.gsub!(/&#39;/, '\'')
      case line
      # <TD class="PageBuilderWidget"><SPAN>Total Records: <B>2938</B> - Page: <B>147</B> of <B>147</B>
      when /PageBuilderWidget[^:]+: \<b\>(\d+)\<\/b\> [^:]+: \<b\>(\d+)\<\/b\> \w* \<b\>(\d+)\<\/b\>/
        if not waypoints_total
          waypoints_total = $1.to_i
          page_number = $2.to_i
          pages_total = $3.to_i
        end
        # href="javascript:__doPostBack('ctl00$ContentBody$pgrTop$ctl08','')"><b>Next &gt;</b></a></td>
        if line =~ /doPostBack\(\'([\w\$_]+)\',\'\'\)\"\>\<b\>[^\>]+ \&gt;\<\/b\>/ #Next
          debug "Found next target: #{$1}"
          post_vars['__EVENTTARGET'] = $1
        end

# 2011-05-04: obsolete (match below!)
      #<IMG src="./gc_files/8.gif" alt="Unknown Cache" width="32" height="32"></A>
      #<img src="http://[...]/wpttypes/sm/8.gif" alt="Unknown Cache"[...]>
      when /cache_details.*\/WptTypes\/[\w].*?alt=\"(.*?)\"/
        displayError "obsolete when line 514"

# 2011-05-04: obsolete
      # trackables: all in one separate line, usually after the cache type line
      # <img src="http://www.geocaching.com/images/wpttypes/21.gif" alt="Travel Bug Dog Tag (1 item)" title="Travel Bug Dog Tag (1 item)" /> \
      # ... <img src="/images/WptTypes/coins.gif" alt="Geocoins:  Happy Caching - Black Cat Geocoin (1), Geocaching meets Geodäsie Geocoin (1)" title="Geocoins:  Happy Caching - Black Cat Geocoin (1), Geocaching meets Geodäsie Geocoin (1)" />
      # or
      # <img src="/images/travelbugsicon.gif" alt="Travel Bug Dog Tag (2 items)" title="Travel Bug Dog Tag (2 items)" /> \
      # ... <img src="http://www.geocaching.com/images/wpttypes/2934.gif" alt="Africa Geocoin (1 item(s))" title="Africa Geocoin (1 item(s))" />
      # only count for TBs, coins by name - single-coin and multi-coin cases!
      when /\/wpttypes\/\d+\.gif\".*?alt=\".*? \((.*?) item(\(s\))?\)\"/
        displayError "obsolete when line 525"

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

# 2011-05-04: obsolete
      # (2/1)<br />
      # (1/1.5)<br />
      when /\(([-\d\.]+)\/([-\d\.]+)\)\<br/
        displayError "obsolete when line 546"

# 2011-05-04: obsolete
      # <img src="/images/icons/container/micro.gif" alt="Size: Micro" />
      when /\<img src=\"\/images\/icons\/container\/.*\" alt=\"Size: (.*?)\"/
        displayError "obsolete when line 551"

# 2011-05-04: unchanged
      #                             11 Jul 10<br />
      # Yesterday<strong>*</strong><br />
      when /^ +((\w+[ \w]+)|([0-9\/\.-]+))(\<strong\>)?(\*)?(\<\/strong\>)?\<br/
        debug "last found date: #{$1}#{$5} at line: #{line}"
        cache['mtime'] = parseDate($1+$5.to_s)
        cache['mdays'] = daysAgo(cache['mtime'])
        debug "mtime=#{cache['mtime']} mdays=#{cache['mdays']}"

# 2011-06-15: found date (only when logged in)
      # found date:
      # <span id="ctl00_ContentBody_dlResults_ctl??_uxUserLogDate" class="Success">5 days ago</span></span>
      # <span id="ctl00_ContentBody_dlResults_ctl01_uxUserLogDate" class="Success">Today<strong>*</strong></span></span>
      when /^ +\<span [^\>]*UserLogDate[^\>]*\>((\w+[ \w]+)|([0-9\/\.-]+))(\<strong\>)?(\*?)(\<\/strong\>)?\<\/span\>\<\/span\>/
        debug "user found date: #{$1}#{$4} at line: #{line}"
        cache['atime'] = parseDate($1+$5.to_s)
        cache['adays'] = daysAgo(cache['atime'])
        debug "atime=#{cache['atime']} adays=#{cache['adays']}"

# 2011-05-04: appended </span>
      # creation date: date alone on line
      #  9 Sep 06</span>
      # may have a "New!" flag next to it
      #  6 Dec 10 <img src="[...]" alt="New!" title="New!" /></span>
      when /^ +((\d+ \w{3} \d+)|([0-9\/\.-]+))(\s+\<img [^\>]* title="New!" \/\>)?<\/span>\s?$/
        debug "create date: #{$1} at line: #{line}"
        cache['ctime'] = parseDate($1)
        cache['cdays'] = daysAgo(cache['ctime'])
        debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"

# 2011-05-04: obsolete
      #     <img src="/images/icons/compass/NW.gif" alt="NW" title="NW" />NW<br />0.1mi
      # GC user prefs set to imperial units
      when /\>([NWSE]+)\<br \/\>([\d\.]+)mi/
        displayError "obsolete when line 587"
      # or  <img src="/images/icons/compass/SE.gif" alt="SE" title="SE" />SE<br />6.7km
      # GC user prefs set to metric units
      when /\>([NWSE]+)\<br \/\>([\d\.]+)km/
        displayError "obsolete when line 591"
      # or just              <br />Here
      when /^\s+\<br \/\>Here\s?$/
        # less than 0.01 miles
        displayError "obsolete when line 595"

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
          dist = dist.to_f / 1.609344
        elsif (dist =~ /ft/)
          dist = dist.to_f / 5280
        else
          dist = dist.to_f
        end
        cache['distance'] = dist
        cache['direction'] = dir

# 2011-05-04: unchanged
      # 2010-12-22:
      # <span id="ctl00_ContentBody_dlResults_ctl01_uxFavoritesValue" title="0" class="favorite-rank">0</span>
      when /_uxFavoritesValue[^\>]*\>([0-9]+)\</
        favs = $1
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

        cache['name']=name.gsub(/ +$/, '')
        debug "guid=#{cache['guid']} name=#{cache['name']} (disabled=#{cache['disabled']}, archived=#{cache['archived']})"

# 2011-05-04: unchanged
      # by gonsuke@Zerosen and Bakatono@Zerosen
      when /^ +by (.*?)$/
        creator = $1
        cache['creator'] = creator.gsub(/\s+$/, '')
        debug "creator=#{cache['creator']}"

# 2011-05-04: obsolete
      # (GC1Z0RT)<br />
      when /^ +\((GC.*?)\)\<br \/\>/
        displayError "obsolete when line 699"

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
        debug "Country/state found #{$2}/#{$3}"
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

      when /^\s+<\/tr\>/
        debug "--- end of row ---"
        if wid and not @waypoints.has_key?(wid)
          debug "- closing #{wid} record -"
          parsed_total += 1
          if not cache['mtime']
            cache['mdays'] = -1
            cache['mtime'] = Time.at(0)
          end
          if not cache['atime']
            cache['adays'] = -1
            cache['atime'] = Time.at(0)
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

      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\" \/\>/
        debug "found hidden post variable: #{$1}"
        post_vars[$1]=$2

      end # end case
    } # end loop
    debug "processPage done: page:#{page_number} total_pages: #{pages_total} parsed: #{parsed_total}"
    return [page_number, pages_total, parsed_total, post_vars]
  end #end parsecache
end
