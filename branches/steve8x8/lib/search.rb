# $Id$

require 'cgi'
require 'geocode'
require 'shadowget'
require 'time'


class SearchCache
  include Common
  include Messages

  attr_accessor :distance

  @@base_url = 'http://www.geocaching.com/seek/nearest.aspx'

  def initialize
    @distance = 15
    @ttl = 72000
    @waypoints = Hash.new
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
      lat_dir, lat_h, lat_ms, long_dir, long_h, long_ms, lat_ns, long_ew = parseCoordinates(key)
      @search_url = @@base_url + '?lat_ns=' + lat_ns.to_s + '&lat_h=' + lat_h + '&lat_mmss=' + (lat_ms==''?'0':lat_ms) + '&long_ew=' + long_ew.to_s + '&long_h=' + long_h + '&long_mmss=' + (long_ms==''?'0':long_ms)

    when 'user'
      @query_type = 'ul'
      @ttl = 43200

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

  def parseCoordinates(key)
    # This regular expression should probably handle any kind of mess. Thanks sbrynen!
    re = /^([ns-]?)\s*([\d\.]+)\W*([\d\.]*)[\s,]+([ew-]?)\s*([\d\.]+)\W*([\d\.]+)/i
    md = re.match(key)
    if ! md
      displayError "Bad format in #{key}! Try something like \"N56 44.392 E015 52.780\" instead"
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
    displayMessage "Coordinates have been parsed as latitude #{lat_dir} #{lat_h}'#{lat_ms}, longitude #{long_dir} #{long_h}'#{long_ms}"
    coords = [lat_dir, lat_h, lat_ms, long_dir, long_h, long_ms, lat_ns, long_ew]
    return coords
  end

  def getResults()
    debug "Getting results: #{@query_type} at #{@search_url}"
    if @query_type == 'wid'
      @waypoints[@query_arg] = getWidSearchResult(@search_url)
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
    cache_data = {
      'guid' => guid,
      'disabled' => false,
      'archived' => false,
      'membersonly' => false
    }
    return cache_data
  end

  def searchResults(url)
    debug "searchResults: #{url}"
    if not url
      warn "searchResults has no URL?"
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

    while(page_number < pages_total)
      debug "*** On page #{page_number} of #{pages_total}"
      last_page_number = page_number
      page_number, total_pages, total_waypoints, post_vars, src = processPage(post_vars)
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
    end
    return @waypoints
  end

  def getPage(url, post_vars)
    page = ShadowFetch.new(url)
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
      'disabled' => false,
      'archived' => false,
      'membersonly' => true
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
      when /Total Records: \<b\>(\d+)\<\/b\> - Page: \<b\>(\d+)\<\/b\> of \<b\>(\d+)\<\/b\>/
        if not waypoints_total
          waypoints_total = $1.to_i
          page_number = $2.to_i
          pages_total = $3.to_i
        end
        # href="javascript:__doPostBack('ctl00$ContentBody$pgrTop$ctl08','')"><b>Next &gt;</b></a></td>
        if line =~ /doPostBack\(\'([\w\$_]+)\',\'\'\)\"\>\<b\>Next/
          debug "Found next target: #{$1}"
          post_vars['__EVENTTARGET'] = $1
        end

      #<IMG src="./gc_files/8.gif" alt="Unknown Cache" width="32" height="32"></A>
      when /WptTypes\/[\w].*?alt=\"(.*?)\"/
        full_type = $1
        cache['fulltype'] = full_type
        debug "Creating short type for #{full_type}"
        cache['type'] = full_type.split(' ')[0].downcase.gsub(/\-/, '')
        # two special cases: "Cache In Trash Out" and "Lost and Found"
        case full_type
        when /Cache In Trash Out/
          cache['type'] = 'cito'
        when /Lost [Aa]nd Found/
          cache['type'] = 'lost+found'
        end
        debug "type=#{cache['type']}"
        cache['mdays'] = -1

      # trackables: all in one separate line, usually after the cache type line
      # <img src="http://www.geocaching.com/images/wpttypes/21.gif" alt="Travel Bug Dog Tag (1 item)" title="Travel Bug Dog Tag (1 item)" /> \
      # ... <img src="/images/WptTypes/coins.gif" alt="Geocoins:  Happy Caching - Black Cat Geocoin (1), Geocaching meets Geodäsie Geocoin (1)" title="Geocoins:  Happy Caching - Black Cat Geocoin (1), Geocaching meets Geodäsie Geocoin (1)" />
      # or
      # <img src="/images/travelbugsicon.gif" alt="Travel Bug Dog Tag (2 items)" title="Travel Bug Dog Tag (2 items)" /> \
      # ... <img src="http://www.geocaching.com/images/wpttypes/2934.gif" alt="Africa Geocoin (1 item(s))" title="Africa Geocoin (1 item(s))" />
      # only count for TBs, coins by name - single-coin and multi-coin cases!
      when /\/wpttypes\/\d+\.gif\".*?alt=\".*? \((.*?) item(\(s\))?\)\"/
        # This line has travel bug data
        debug "List of trackables: #{line}"
        trackables = ''
        # split at alt tag, drop everything before
        line.gsub(/^.*?alt=\"/, '').split(" alt=\"").each { |item|
          debug "trackable item #{item}"
          # "Travel Bug Dog Tag (1 item)" ...
          # "Travel Bug Dog Tag (2 items)" ...
          # "Africa Geocoin (1 item(s))" ...
          # "Geocoins:  Happy Caching - Black Cat Geocoin (1), Geocaching meets Geodäsie Geocoin (1)" ...
          # "Cachekinz (1 item(s))" ...
          # "Unite for Diabetes Travel Bug (1 item(s))" ...
          item.gsub!(/\".*/, '')
          # shorten the name a bit
          item.gsub!(/^Geocoins:\s+/, '')
          item.gsub!(/Travel Bug( Dog Tag)?/, 'TB')
          item.gsub!(/Geocoin/, 'GC')
          item.gsub!(/^The /, '')
          # drop counter if 1
          item.gsub!(/ \((.*?) item\(?s?\)?\)/) {"(#{$1})"}
          item.gsub!(/\(1\)/, '')
          trackables << item + ', '
        }
        if trackables.length > 0
          trackables.gsub!(/, $/, '')
          debug "Trackables Found: #{trackables}"
          cache['travelbug'] = trackables
        end

      # (2/1)<br />
      # (1/1.5)<br />
      when /\(([-\d\.]+)\/([-\d\.]+)\)\<br/
        # Use integers when we can
        if $1.to_f == $1.to_i
          cache['difficulty']=$1.to_i
        else
          cache['difficulty']=$1.to_f
        end

        if $1.to_f == $1.to_i
          cache['terrain']=$2.to_i
        else
          cache['terrain']=$2.to_f
        end
        debug "difficulty=#{cache['difficulty']} terr=#{cache['terrain']}"

      # <img src="/images/icons/container/micro.gif" alt="Size: Micro" />
      when /\<img src=\"\/images\/icons\/container\/.*\" alt=\"Size: (.*?)\"/
        cache['size'] = $1.downcase
        debug "size=#{cache['size']}"

      #                             11 Jul 10<br />
      # Yesterday<strong>*</strong><br />
      when /^ +(\w+[ \w]+)(\<strong\>)?\*?(\<\/strong\>)?\<br/
        debug "last found date: #{$1} at line: #{line}"
        cache['mtime'] = parseDate($1)
        cache['mdays'] = daysAgo(cache['mtime'])
        debug "mtime=#{cache['mtime']} mdays=#{cache['mdays']}"

      # creation date: date alone on line
      #  9 Sep 06
      when /^ +(\d+ \w{3} \d+)\s?$/
        debug "create date: #{$1} at line: #{line}"
        cache['ctime'] = parseDate($1)
        cache['cdays'] = daysAgo(cache['ctime'])
        debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"

      #     <img src="/images/icons/compass/NW.gif" alt="NW" title="NW" />NW<br />0.1mi
      # GC user prefs set to imperial units
      when /\>([NWSE]+)\<br \/\>([\d\.]+)mi/
        cache['distance'] = $2.to_f
        cache['direction'] = $1
        debug "cacheDistance=#{cache['distance']}mi dir=#{cache['direction']}"
      # or  <img src="/images/icons/compass/SE.gif" alt="SE" title="SE" />SE<br />6.7km
      # GC user prefs set to metric units
      when /\>([NWSE]+)\<br \/\>([\d\.]+)km/
        cache['distance'] = $2.to_f / 1.609344
        cache['direction'] = $1
        debug "cacheDistance=#{cache['distance']}mi dir=#{cache['direction']}"
      # or just              <br />Here
      when /^\s+\<br \/\>Here\s?$/
        # less than 0.01 miles
        cache['distance'] = 0.0
        cache['direction'] = "N"
        debug "cacheDistance=#{cache['distance']}mi dir=#{cache['direction']}"

      # <a href="/seek/cache_details.aspx?guid=c9f28e67-5f18-45c0-90ee-76ec8c57452f">Yasaka-Shrine@Zerosen</a>
      when /cache_details.aspx\?guid=(.*?)\">(.*?)\<\/a\>/
        cache['guid']=$1
        name = $2
        debug "Found cache details link for #{name}"

        if name =~ /class=\"Warning/ or name =~ /class=\"OldWarning/
          cache['archived'] = true
          debug "#{name} appears to be archived"
        else
          cache['archived'] = false
        end

        if name =~ /Strike"\>(.*?)\<\//
          cache['disabled'] = true
          debug "#{name} appears to be disabled"
          name=$1
        else
          cache['disabled'] = false
        end

        cache['name']=name.gsub(/ +$/, '')
        debug "guid=#{cache['guid']} name=#{cache['name']} (disabled=#{cache['disabled']}, archived=#{cache['archived']})"

      # by gonsuke@Zerosen and Bakatono@Zerosen
      when /^ +by (.*?)$/
        creator = $1
        cache['creator'] = creator.gsub(/\s+$/, '')
        debug "creator=#{cache['creator']}"

      # (GC1Z0RT)<br />
      when /^ +\((GC.*?)\)\<br \/\>/
        wid = $1
        debug "wid=#{wid}"

      # country/state: prefixed by 28 blanks
      # Mecklenburg-Vorpommern, Germany
      # East Midlands, United Kingdom
      # Comunidad Valenciana, Spain
      # North Carolina (will be interpreted as country, not U.S. state!)
      # also valid (country only):
      # Croatia; Isle of Man; Bosnia and Herzegovina, St. Martin, Guinea-Bissau; Cocos (Keeling) Islands
      #             |>$2|    |->$3 -------------------------------|
      when /^\s{28}((.*?), )?([A-Z][a-z]+\.?([ -]\(?[A-Za-z]+\)?)*)\s?$/
        debug "COUNTRY STATE 2=#{$2} 3=#{$3}"
        if ($3 != "Icons" && $3 != "Placed" && $3 != "Description" && $3 != "Last Found")
          # special case US states:
          if (usstates[$3])
            cache['country'] = 'United States'
            cache['state'] = $3
          else
            cache['country'] = $3
            cache['state'] = ($2)?$2:'-' # GCStatistic doesn't like empty state elements
          end
          debug "COUNTRY #{cache['country']} STATE #{cache['state']}"
        end

      # small_profile.gif" alt="Premium Member Only Cache" with="15" height="13"></TD
      when /Premium Member Only Cache/
        debug "#{wid} is a members only cache. Marking"
        cache['membersonly'] = true

      when /^\s+<\/tr\>/
        debug "--- end of row ---"
        if wid and not @waypoints.has_key?(wid)
          debug "- closing #{wid} record -"
          parsed_total += 1
          if not cache['mtime']
            cache['mdays'] = -1
            cache['mtime'] = Time.at(0)
          end

          @waypoints[wid] = cache.dup
          @waypoints[wid]['visitors'] = []

          # if our search is for caches that have been done by a particular user, add to the hash
          if @query_type == "users"
            @waypoints[wid]['visitors'].push(@key.downcase)
          end
          cache.clear
        end

      when /^\<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\" \/\>/
        debug "found hidden post variable: #{$1}"
        post_vars[$1]=$2

      end # end case
    } # end loop
    debug "processPage done: page:#{page_number} total_pages: #{pages_total} parsed: #{parsed_total}"
    return [page_number, pages_total, parsed_total, post_vars]
  end #end parsecache
end