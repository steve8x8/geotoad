require 'cgi'
require 'time'
require 'interface/messages'
require 'lib/common'
require 'lib/constants'
require 'lib/country_state'
require 'lib/shortentype'
require 'lib/geocode'
require 'lib/shadowget'

class SearchCache

  include Common
  include Messages
  include ShortenType

  attr_writer :distance
  attr_writer :max_pages

  @@base_url = 'https://www.geocaching.com/seek/nearest.aspx'

  def initialize
    @distance = 15
    @max_pages = 0		# unlimited
    @ttl = 20 * $HOUR
    @waypoints = Hash.new
    # no need for $USStates anymore, use CountryState.findMatchingState
    @cs = CountryState.new

# synced with c:geo 2020-07-02
# cache types from search form 2023-05-12
# $cachetypetx -> $CacheTypes_TX
# @cachetypenum -> $CacheTypes
    @txfilter = nil

    # exclude own found
    @notyetfound = false
  end

  def txfilter=(cacheType)
    # may return nil if not found
    @txfilter = $CacheTypes_TX[cacheType].dup
    @txfilter << '&children=n' if (@txfilter and (@txfilter !~ /children=/))
    debug "Setting txfilter to \"#{cacheType}\", now #{@txfilter.inspect}"
  end

  def notyetfound=(truefalse)
    @notyetfound = truefalse
  end

  def setType(mode, key)
    @search_url = nil
    @query_type = nil
    @query_arg = key
    supports_distance = false
    case mode
    when 'location'
      @query_type = 'location'
      supports_distance = true
      geocoder = GeoCode.new()
      importance, lat, lon, location, count = geocoder.lookup_location(key)
      debug "geocoder returned: a:#{importance.inspect} x:#{lat} y:#{lon}"
      if not importance
        displayWarning "GeoCoder failed to determine the location of #{key}"
        return nil
      end
      # trim numbers to useful precision, leave one trailing zero digit
      importance = sprintf("%.3f", importance).gsub(/0{1,2}$/, '')
      lat = sprintf("%.6f", lat).gsub(/0{1,5}$/, '')
      lon = sprintf("%.6f", lon).gsub(/0{1,5}$/, '')
      debug "GeoCoder returned result for \"#{key}\""
      debug "Using result 1 of #{count}: \"#{location}\""
      displayInfo "Result importance #{importance}, will use coordinates #{lat}, #{lon}"
      @search_url = @@base_url + "?lat=#{lat}&lng=#{lon}"

    when 'coord'
      @query_type = 'coord'
      supports_distance = true
      lat, lon = parseCoordinates(key)
      lat = sprintf("%.6f", lat).gsub(/0{1,5}$/, '')
      lon = sprintf("%.6f", lon).gsub(/0{1,5}$/, '')
      displayInfo "Will use coordinates #{lat}, #{lon}"
      @search_url = @@base_url + "?lat=#{lat}&lng=#{lon}"

    when 'user'
      @query_type = 'ul'
      @ttl = 20 * $HOUR

    when 'owner'
      @query_type = 'u'
      @ttl = 1 * $DAY

    when 'country'
      @query_type = 'country'
      @search_url = @@base_url + "?country_id=#{key}&as=1"
      @ttl = 1 * $DAY

    when 'state'
      @query_type = 'state'
      @search_url = @@base_url + "?state_id=#{key}"
      @ttl = 1 * $DAY

    when 'keyword'
      @query_type = 'key'

    when 'wid'
      @query_type = 'wid'
      @query_arg = key.upcase
      @search_url = "https://www.geocaching.com/seek/cache_details.aspx?wp=#{key.upcase}"

    when 'guid'
      @query_type = 'guid'
      @query_arg = key.downcase
      @search_url = "https://www.geocaching.com/seek/cache_details.aspx?guid=#{key.downcase}"

    when 'bookmark'
      displayInfo "Bookmark Key #{key}"
      @query_type = 'bookmark'
      # GUID style forwards to List style now (2024)
      if key.downcase =~ /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
        displayWarning "GUID style"
        @query_arg = key.downcase
        @search_url = "https://www.geocaching.com/bookmarks/view.aspx?guid=#{key.downcase}"
      else
        displayWarning "List style"
        @query_arg = key.upcase
        @search_url = "https://www.geocaching.com/plan/lists/#{key.upcase}"
      end
    end

    if not @query_type
      displayWarning "Invalid query type: #{mode}. Valid types include: location, coord, keyword, wid"
      return nil
    end

    if not @search_url
        @search_url = @@base_url + '?' + @query_type + '=' + CGI.escape(@query_arg.to_s)
    end

    if @txfilter
        # old style: most stable
        @search_url << '&tx=' + @txfilter
        # used by the nearest.aspx web interface
        #@search_url << '&ex=0&cFilter=' + @txfilter
        #@search_url << '&cFilter=' + @txfilter
    end

    if @notyetfound
        @search_url << '&f=1'
    end

    if supports_distance and @distance
        @search_url << '&dist=' + @distance.to_s
    end

    debug @search_url
    return @query_type
  end

  def getResults()
    debug3 "Getting results: #{@query_type} at #{@search_url}"
    if @query_type == 'wid'
      waypoint = getWidSearchResult(@search_url)
      if not waypoint
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
      if not waypoint
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
      waypoints = []
      totalpages = 1
      loopcount = 0
      maxloopcount = 100
      # completeness: first number must be > 20 * second
      # special case: empty search
      while loopcount < maxloopcount and totalpages > 0 and waypoints.length <= 20 * (totalpages - 1)
        waypoints, totalpages = searchResults(@search_url)
        # -L option causes less pages to be returned
        if @max_pages != 0 and totalpages > @max_pages
          totalpages = @max_pages
        end
        if  totalpages > 0 and waypoints.length <= 20 * (totalpages - 1)
          displayWarning "Search results incomplete: #{waypoints.length} caches from #{totalpages} pages"
          # note: previous pages have been cached and will be used "local"
          loopcount += 1
          if loopcount < maxloopcount
            # progressive sleep instead of simple "sleep(10 * loopcount)"
            sleeptime = (4 + 1.05 ** loopcount).ceil
            displayInfo "Restarting query after #{sleeptime} seconds ..."
            sleep(sleeptime)
          end
        end
      end
      if  totalpages > 0 and waypoints.length <= 20 * (totalpages - 1)
        displayError "Search results still incomplete after #{maxloopcount} retries", rc = 3
      end
      return waypoints
    end
  end

  def getWidSearchResult(url)
    data, src = getPage(url, {})
    if not data
      displayError "No data to be analyzed! Check network connection!", rc = 7
    end
    guid = nil
    wid = nil
    disabled = false
    archived = false
    membersonly = false
    cartridge = nil
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
    cfavs = nil
    begin
    if data =~ /<title>\s*404 - File Not Found\s*<\/title>/m
      displayWarning "Error 404: Cache unknown/unpublished"
      return "unpublished"
    end
    data.split("\n").each{ |line|
      line.gsub!(/&#39;/, '\'')
      case line
      # wherigo cartridge link
      # http://www.wherigo.com/cartridge/details.aspx?CGUID=...
      # http://www.wherigo.com/cartridge/download.aspx?CGUID=...
      when /(www\.wherigo\.com\/cartridge\/\w+.aspx\?CGUID=([0-9a-f-]{36}))/
        debug "Wherigo cartridge at #{$1}"
        # do not overwrite with later ones
        if not cartridge
          cartridge = $2
        end
      # <span id="ctl00_litPMLevel">Basic Member</span>
      when /id=\"ctl00_litPMLevel\">([^>]+)</
        debug "Membership confirmed as \"#{$1}\""
        $membership = $1
      # <a id="hlUpgrade" accesskey="r" title="Upgrade to Premium" class="LinkButton" href="https://payments.geocaching.com">Upgrade to PREMIUM</a>
      when /id=\"hlUpgrade\"[^>]*Upgrade to Premium/
        debug "Premium Member upgrade option found"
      when /Geocaching . Hide and Seek a Geocache . Unpublished Geocache/
        # shown to non-owner only!
        displayWarning "Unpublished cache, skipping"
        break
      # BM sees: Geocaching > Hide and Seek a Geocache > Premium Member Only Cache
      # PM sees: <p class="Warning NoBottomSpacing">This is a Premium Member Only cache.</p>
      when /[>a] Premium Member Only Cache/i
        debug "Premium Member cache detected"
        membersonly = true
      when /^\s+GC.*\((.*)\) in ((.*), )?(.*) created by (.*?)\s*$/
        ctype = $1
        state = $3
        country = $4
        owner = $5
        if ctype =~ /Mystery Cache/
          ctype = "Unknown Cache"
        end
        # 2014-08-26
        if ctype =~ /Traditional Geocache/
          ctype = "Traditional Cache"
        end
        if ctype =~ /EarthCache/
          ctype = "Earthcache"
        end
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
      # modified 2018-12-31
      when /<meta[^>]+name=\"og:url\"[^>]+content=\"https?:\/\/coord.info\/(GC\w+)./
        wid = $1
        debug "Found WID: #{wid} (coord.info)"
      when /<meta[^>]+name=\"og:url\"[^>]+content=\"https?:\/\/www.geocaching.com\/seek\/cache_details.aspx?wp=(GC\w+)/
        wid = $1
        debug "Found WID: #{wid} (cache_details)"
      # added 2012-05-15:
      #<span id="ctl00_ContentBody_CoordInfoLinkControl1_uxCoordInfoCode" class="CoordInfoCode">GCZFC2</span>
      when /class=\"CoordInfoCode\">(GC\w+)<\/span>/
        wid = $1
        debug "Found WID: #{wid} (CoordInfo)"
      #<input type="submit" name="ctl00$ContentBody$btnSendToPhone" value="Send to My Phone" onclick="s2phone(&#39;GC332MT&#39;);return false;" id="ctl00_ContentBody_btnSendToPhone" />
      when /onclick=\"s2phone\(.*?(GC\w+).*?\);return/
        wid = $1
        debug "Found WID: #{wid} (s2phone)"
      # premium-member only
      when /WptTypeImage.*\/(wpttypes|play\/Content\/images\/cache-types)\/(\w+)\./i
        ccode = $2
        # list covers only "standard" types! This may be incorrect
        if $CacheTypes[ccode]
          ctype = $CacheTypes[ccode]
        else
          displayWarning "Cache image code #{ccode.inspect} for WID #{wid.inspect} A - please report!"
          displayInfo "#{line}"
          ctype = 'Unknown Cache'
        end
        debug "Found PMO type code #{ccode} -> #{ctype}"
      # premium-member only, March 2019
      when /\/sprites\/cache-types.svg#icon-(\d+)/i
        ccode = $1
        # list covers only "standard" types! This may be incorrect
        if $CacheTypes[ccode]
          ctype = $CacheTypes[ccode]
        else
          displayWarning "Cache image code #{ccode.inspect} for WID #{wid.inspect} A - please report!"
          displayInfo "#{line}"
          ctype = 'Unknown Cache'
        end
        debug "Found PMO type code #{ccode} -> #{ctype}"
      when /\s+\((GC\w+)\)<\/h2>/
        wid = $1
        debug "Found PMO WID: #{wid}"
      # <form ... action="../seek/cache_pmo.aspx?wp=GC4V7ZH&amp;title=froehliche-weihnachten&amp;guid=2718079c-9da2-4962-8618-37ca1820bde8" id="aspnetForm">
      when /cache_pmo.aspx\?wp=(GC\w+).amp;(.*guid=([0-9a-f-]{36}))?/
        wid = $1
        guid = $3
        debug "Found PMO WID: #{wid.inspect} GUID: #{guid.inspect}"
      # attention: the following also matches links in comments, avoid overwriting
      when /cache_\w+.aspx\?wp=(GC\w+).amp;(.*guid=([0-9a-f-]{36}))?/
        if not wid
          wid = $1
          guid = $3
          debug "Found (PMO?) WID: #{wid.inspect} GUID: #{guid.inspect}"
        end
      when /uxCache(Type|By)\">A cache by (.*?)\s*</
        owner = $2
        debug "Found PMO owner: #{owner.inspect}"
      when /The owner of <strong>(.*?)<\/strong> has chosen to make/
        cname = $1
        debug "Found PMO cache name: #{cname.inspect}"
      when /<h1 class=.heading-\d.>(.*?)\s*<\//
        cname = $1
        debug "Found PMO cache name: #{cname.inspect}"
      # for filtering; don't care about ".0" representation
      when /_uxLegendScale.*?(\d(\.\d)?) out of/
        cdiff = tohalfint($1)
        debug "Found D: #{cdiff}"
      when /_Localize12.*?(\d(\.\d)?) out of/
        cterr = tohalfint($1)
        debug "Found T: #{cterr}"
      # this causes problems when using a language != English
      #when /alt=\"Size: .*?>\((.*?)\)</
      # better use a match on the corresponding image
      # Size:&nbsp;<span class="minorCacheDetails"><img src="/images/icons/container/regular.gif" alt="Size: regular" title="Size: regular" />&nbsp<small>(regular)</small></span>
      # (PMO) <img src="/images/icons/container/large.gif" alt="Size: Large" />&nbsp<small>(Large)</small>&nbsp;
      when /images\/icons\/container\/(\w*)\./
        csize = $1.downcase
        debug "Found size: #{csize}"
      when /_CacheName\">\s*(.*?)\s*<\/span>/
        cname = $1
        debug "Found cache name: #{cname.inspect}"
      when /\s*A cache by <a[^>]*>\s*(.*?)\s*<\/a/
        owner = $1
        debug "Found owner: #{owner.inspect}"
      end
    }
    rescue => error
      displayWarning "Error in getWidSearchResult():data.split"
      if data =~ /(\+\(|_|CoordInfoCode\">)(GC\w+)(\)\+[^>]+>Google Maps|[^>]+>Bing Maps|<\/span>)/
        displayWarning "WID affected: #{$2}"
      end
      raise error
    end
    # creation/event date
    #                 <div id="ctl00_ContentBody_mcd2">
    #                Hidden:
    #                10/11/2011
    # 2013-08-21: "Hidden\n:"
    if data =~ /<div[^>]*mcd2\">\s*[\w ]*\s*:\s*([\w\/\. -]+)\s+</m
      debug "Found creation date: #{$1}"
      ctime = parseDate($1)
      cdays = daysAgo(ctime)
    end
    # one match is enough!
    if data =~ /cdpf\.aspx\?guid=([0-9a-f-]{36})/m
      guid = $1
      debug "Found GUID: #{guid}"
    end
    if data =~ /Cache Issues:.*class=\"OldWarning\".*This cache is temporarily unavailable/
      disabled = true
      debug "Cache appears to be disabled"
    end
    if data =~ /Warning.*This cache listing has been archived/
      archived = true
      debug "Cache appears to be archived"
    end
    if data =~ /Your geocache has not yet been submitted./
      disabled = true
      displayWarning "Cache has not been submitted"
    end
    if data =~ /Your cache has been submitted for review./
      disabled = true
      displayWarning "Cache has not been reviewed"
    end
    if data =~ /you need to resubmit your cache for review./
      disabled = true
      displayWarning "Cache has not been re-submitted"
    end
    if data =~ /Cache Issues:.*class=\"OldWarning\".*This cache has been archived/
      archived = true
      debug "Cache appears to be archived"
    end
    if data =~ /<h.[^>]*>\s*This cache has been archived.\s*<\/h.>/m
      archived = true
      debug "Cache appears to be archived"
    end
    # premium-member only
    #         <strong>
    #        <span id="ctl00_ContentBody_lblDifficulty">Difficulty:</span></strong>
    #    <img src="http://www.geocaching.com/images/stars/stars1_5.gif" alt="1.5 out of 5" />&nbsp;
    #    <strong>
    #        <span id="ctl00_ContentBody_lblTerrain">Terrain:</span></strong>
    #    <img src="http://www.geocaching.com/images/stars/stars1_5.gif" alt="1.5 out of 5" />
    if data =~ /lblDifficulty\".*?(\d(\.\d)?)( out of 5|<\/)/m
      cdiff = tohalfint($1)
      debug "Found PMO D: #{cdiff}"
    end
    if data =~ /lblTerrain\".*?(\d(\.\d)?)( out of 5|<\/)/m
      cterr = tohalfint($1)
      debug "Found PMO T: #{cterr}"
    end
    if data =~ /lblSize\".*?<span>(\w*)<\//m
      csize = $1.downcase
      debug "Found PMO S: #{csize}"
    end
    if data =~ /lblFavoritePoints\".*?<span>(\d*)<\//m
      cfavs = $1
      debug "Found PMO F: #{cfavs}"
    end
    if data =~ /<span class=.favorite-value.>\s*(\d+)\s*<\//
      cfavs = $1
      debug "Found F: #{cfavs}"
    end

    cache_data = {
      'guid' => guid,
      'wid' => wid,
      'disabled' => disabled,
      'archived' => archived,
      'membersonly' => membersonly,
      'cartridge' => cartridge,
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
      'favorites' => cfavs,
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

    # get first result page
    page_number, pages_total, waypoints_total, post_vars, src = processPage({})
    progress = ProgressBar.new(1, pages_total, "Search results")
    progress.updateText(page_number, "page #{page_number} (#{src})")

    if waypoints_total.to_i <= 0
      displayMessage "No geocaches were found."
      return [@waypoints, 0]
    end

    if not page_number
      displayWarning "Could not determine current page number from #{url}"
      displayError   "Please set language to English on GC.com as a workaround.", rc = 1
      return [@waypoints, 0]
    end

    if not pages_total
      displayWarning "Could not determine total pages from #{url}"
      displayError   "Please set language to English on GC.com as a workaround.", rc = 1
      return [@waypoints, 0]
    end

    # special case: only first page
    if @max_pages == 1
      debug "Limiting to first search page"
      return [@waypoints, 1]
    end

    while (page_number < pages_total)
      # get subsequent search pages
      debug "*** On page #{page_number} of #{pages_total}"
      last_page_number = page_number
      page_number, pages_total_updated, waypoints_total, post_vars, src = processPage(post_vars)
      debug2 "processPage returns #{page_number}/#{pages_total_updated}, #{waypoints_total} wpts"
      # number of result pages may have changed!
      if pages_total_updated != pages_total
        displayWarning "Result page count changed from #{pages_total} to #{pages_total_updated}, trouble ahead?"
        pages_total = pages_total_updated
        # set new maximum for ProgressBar
        progress.updateText(nil, nil, pages_total)
      end
      progress.updateText(page_number, "page #{page_number} (#{src})")

      if page_number == last_page_number
        displayWarning "Page number not increasing."
        displayError   "Stuck on page number #{page_number} of #{pages_total}", rc = 3
      elsif page_number < last_page_number
        displayWarning "Page number not increasing."
        displayError   "We were on page #{last_page_number}, but just read #{page_number}. Parsing error?", rc = 3
      end
      # limit search page count
      if @max_pages > 0 and page_number >= @max_pages
        displayWarning "Reached page count limit #{@max_pages}"
        # exit loop
        page_number = pages_total
      end

      # if there has been an empty page,
      # do not pollute cache tree with subsequent pages -
      # jump to the end instead
      if src == '?'
        debug2 "Interrupting incomplete query"
        # exit loop
        page_number = pages_total
      end
    end
    return [@waypoints, pages_total]
  end

  def getPage(url, post_vars, pattern = nil)
    page = ShadowFetch.new(url)
    page.localExpiry = @ttl
    if pattern
      page.filePattern = pattern
    end
    if (post_vars.length > 0)
      page.postVars = post_vars.dup
    end

    if page.fetch
      return [page.data, page.src]
    else
      return [nil, nil]
    end
  end

  def processPage(post_vars)
    data, src = getPage(@search_url, post_vars, pattern = "SearchResultsTable")
    page_number, pages_total, waypoints_total, post_vars = parseSearchData(data)
    return [page_number, pages_total, waypoints_total, post_vars, src]
  end


  def parseSearchData(data)
    if not data
      displayError "No data to be analyzed! Check network connection!", rc = 7
    end
    page_number = nil
    pages_total = nil
    waypoints_total = 0
    wid = nil
    waypoints_total = nil
    post_vars = Hash.new
    cache = {
      'disabled' => nil,
      'archived' => nil,
      'membersonly' => false
    }
    inresultstable = false
    begin
    data.split("\n").each{ |line|
      # GC change 2010-11-09
      line.gsub!(/&#39;/, '\'')

      # stuff outside results table
      case line
      # <span id="ctl00_litPMLevel">Basic Member</span>
      when /id=\"ctl00_litPMLevel\">([^>]+)</
        debug "Membership confirmed as \"#{$1}\""
        $membership = $1
      # <a id="hlUpgrade" accesskey="r" title="Upgrade to Premium" class="LinkButton" href="https://payments.geocaching.com">Upgrade to PREMIUM</a>
      when /id=\"hlUpgrade\"[^>]*Upgrade to Premium/
        debug "Premium Member upgrade option found"
      # <td class="PageBuilderWidget"><span>Total Records: <b>718</b> - Page: <b>23</b> of <b>36</b>&nbsp;-&nbsp;</span>
      # pt: <td class="PageBuilderWidget"><span>Total de Registos:: <b>7976</b> - Página: <b>1</b> de <b>399</b>&nbsp;-&nbsp;</span>
      # Note: the only occurrence of utf-8 characters is in the comment above (2013-12-21)
      when /PageBuilderWidget[^:]+:+ +<b>(\d+)<\/b> [^:]+: +<b>(\d+)<\/b>.*?<b>(\d+)<\/b>/
        if not waypoints_total
          waypoints_total = $1.to_i
          page_number = $2.to_i
          pages_total = $3.to_i
          debug2 "Found summary line, total #{$1}, page #{$2} of #{$3}"
        end
        # href="javascript:__doPostBack('ctl00$ContentBody$pgrTop$ctl08','')"><b>Next &gt;</b></a></td>
        if line =~ /doPostBack\(\'([\w\$]+)\',\'\'\)\"><b>([^>]+) \&gt;<\/b>/ #Next
          debug2 "Found next target: #{$1} #{$2.inspect}"
          post_vars['__EVENTTARGET'] = $1
        end
      # at least Dutch is different...
      when /doPostBack\(\'([\w\$]+)\',\'\'\)\"><b>[^>]+ \&gt;<\/b>/ #Next
        debug2 "Found next target: #{$1}"
        post_vars['__EVENTTARGET'] = $1
      when /^<input type=\"hidden\" name=\"(.*?)\".*value=\"(.*?)\" \/>/
        debug2 "found hidden post variable: #{$1}"
        post_vars[$1]=$2
      # GC change 2012-02-14
      # <table class="SearchResultsTable Table"> (search results) </table>
      when /<table class=\"SearchResultsTable/
        debug2 "entering result table"
        inresultstable = true
      when /<table class=\"Table NoBottomSpacing\">/
        if @query_type == 'bookmark'
          debug2 "entering bookmark table"
          inresultstable = true
        end
      when /<\/table>/
        debug2 "leaving result/bookmark table"
        inresultstable = false
      when /<script id=\"__NEXT_DATA__\" type=\"application\/json\">/

require 'json'

        if @query_type == 'bookmark'
          displayInfo "JSON table found"
          inresultstable = true
          json = line.dup
          json.force_encoding("UTF-8")
          json = json.gsub(/^.*<script id=\"__NEXT_DATA__\" type=\"application\/json\">/, "")
          #debug2 "size: #{json.length} #{json[1,50]} ... #{json[json.length-100,json.length-1]}"
          json = json.gsub(/<\/script.*$/, "")
          #debug2 "size: #{json.length} #{json[1,50]} ... #{json[json.length-100,json.length-1]}"
          null = ""
          # what is the difference???
          #jsonhash = JSON.load(json)
          #debug2 "#{jsonhash.inspect}"
          jsonhash = JSON.parse(json)
          debug2 "#{jsonhash.inspect}"
          caches = jsonhash["props"]["pageProps"]["geocaches"]["data"]
          #debug2 "#{caches.inspect}"
          caches.each{ |cache|
            details = {
                           "wid"     => cache["referenceCode"],
                           "text"    => CGI.escapeHTML(cache["name"]),
                           "user"    => CGI.escapeHTML(cache["owner"]),
                           "type"    => cache["geocacheType"],
                           "diff"    => cache["difficulty"],
                           "terr"    => cache["terrain"],
                           "size"    => cache["containerType"],
                           "cdate"   => parseDate(cache["placedDate"].gsub(/T.*/, "")) || Time.at($ZEROTIME),
                           "active"  => cache["state"]["isAvailable"],
                         }
            debug2 "Adding #{details.inspect}"
            # ToDo: build cache hash
          }
          # nothing more to do
          inresultstable = false
        end
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
      when /^ +(\w.*?)(<strong>)?(\*)?(<\/strong>)?<br/
        debug2 "last found date: #{$1}#{$3} at line: #{line}"
        cache['mtime'] = parseDate($1+$3.to_s)
        cache['mdays'] = daysAgo(cache['mtime'])
        debug "mtime=#{cache['mtime']} mdays=#{cache['mdays']}"

# 2011-06-15: found date (only when logged in)
      # found date:
      # <span id="ctl00_ContentBody_dlResults_ctl??_uxUserLogDate" class="Success">5 days ago</span></span>
      # <span id="ctl00_ContentBody_dlResults_ctl01_uxUserLogDate" class="Success">Today<strong>*</strong></span></span>
      when /^ +<span [^>]*UserLogDate[^>]*>(.*?)(<strong>)?(\*?)(<\/strong>)?<\/span><\/span>/
        debug2 "user found date: #{$1}#{$3} at line: #{line}"
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
      when /^\s+(<span[^>]*>\s*)?(([0-9\/\.-]+)|(\d+[ \/\.]\w{3}[ \/\.]\d+)|(\w{3}\/\d+\/\d+))(\s+<img [^>]* title="New!" \/>)?<\/span>\s?(<span class=.Recent.>[^<]*<\/span>)?\s*$/
        debug2 "create date: #{$2} at line: #{line}"
        cache['ctime'] = parseDate($2)
        cache['cdays'] = daysAgo(cache['ctime'])
        debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"

# 2013-05-07: back to the roots
      # <span class="small NoWrap"><img src="/images/icons/compass/S.gif" alt="S" title="S" />S<br />0.1mi</span>
      # <span class="small NoWrap"><br />Here</span>
      when /<span.*?\/compass\/.*?>([NWSE]+)<br \/>([\d\.]+)(mi|ft|km)</
        dir = $1
        dist = $2.to_f
        unit = $3
        if unit =~ /km/
          dist /= $MILE2KM
        elsif unit =~ /ft/
          # 1 mile = 1760 yards = 5280 feet
          dist /= 5280.0
        end
        cache['distance'] = dist
        cache['direction'] = dir
      when /<span[^>]*><br \/>(\w+)<\/span>/
        cache['distance'] = 0.0
        cache['direction'] = 'N'

# 2011-05-04: unchanged
      # 2010-12-22:
      # <span id="ctl00_ContentBody_dlResults_ctl01_uxFavoritesValue" title="0" class="favorite-rank">0</span>
      when /_uxFavoritesValue[^>]*>(\d+)</
        favs = $1.to_i
        debug "found Favorites=#{favs}"
        cache['favorites'] = favs

# 2011-05-04: obsoleted by 2013-08-21 changes
      # <a href="/seek/cache_details.aspx?guid=c9f28e67-5f18-45c0-90ee-76ec8c57452f">Yasaka-Shrine@Zerosen</a>
      # now (2010-12-22, one line!):
      # <a href="/seek/cache_details.aspx?guid=ecfd0038-8e51-4ac8-a073-1aebe7c10cbc" class="lnk">
      # ...<img src="http://www.geocaching.com/images/wpttypes/sm/3.gif" alt="Multi-cache" title="Multi-cache" /></a>
      # ... <a href="/seek/cache_details.aspx?guid=ecfd0038-8e51-4ac8-a073-1aebe7c10cbc" class="lnk  Strike"><span>Besinnungsweg</span></a>
      when /(<img.*?wpttypes\/(\w+)\.[^>]*alt=\"(.*?)\".*)?cache_details.aspx\?guid=([0-9a-f-]{36})([^>]*)><span>\s*(.*?)\s*<\/span><\/a>/i
        debug "Found cache details link for #{name}"
        debug "found cd ccode=#{$2} type=#{$3} guid=#{$4} name=#{$6}"
        ccode = $2
        full_type = $3
        cache['guid'] = $4
        strike = $5
        name = $6
        # traditional_72 etc.
        if ccode =~ /^(\w+)_\d+/
          ccode = $1
        end
        if $CacheTypes[ccode]
          full_type = $CacheTypes[ccode]
        else
          displayWarning "Cache image code #{ccode.inspect} for type #{full_type.inspect} B - please report!"
          displayInfo "#{line}"
        end
        # there may be more than 1 match, don't overwrite
        cache['type'], full_type = shortenType(full_type)
        if cache['fulltype']
          debug "Not overwriting \"#{cache['fulltype']}\" (#{cache['type']}) with \"#{full_type}\""
        else
          cache['fulltype'] = full_type
        end
        if cache['fulltype'] =~ /Event/
            cache['event'] = true
        end
        debug "short type=#{cache['type']} for #{full_type}"

        # AFAIK only "user" queries actually return archived caches
        # class="lnk OldWarning Strike Strike"><span>Lars vom Mars</span></a>
        # class="lnk  Strike"><span>Rund um den See, # 04</span></a>
        if strike =~ /class=\"[^\"]*Warning/
          cache['archived'] = true
          debug "#{name} appears to be archived"
#        else
#          cache['archived'] = false
        end

        if strike =~ /class=\"[^\"]*Strike/
          cache['disabled'] = true
          debug "#{name} appears to be disabled"
#        else
#          cache['disabled'] = false
        end

        cache['name'] = name.gsub(/  */, ' ')
        debug "guid=#{cache['guid']} name=#{cache['name']} (disabled=#{cache['disabled']}, archived=#{cache['archived']})"

      # 2013-08-21:
      when /(<img.*?wpttypes\/(\w+)\.[^>]*alt=\"(.*?)\".*)?\/geocache\/(GC[0-9A-Z]+)([^>]*)><span>\s*(.*?)\s*<\/span><\/a>/i
        debug "Found cache details link for #{name}"
        debug "found gc ccode=#{$2} type=#{$3} wid=#{$4} name=#{$6}"
        ccode = $2
        full_type = $3
        strike = $5
        name = $6
        # traditional_72 etc.
        if ccode =~ /^(\w+)_\d+/
          ccode = $1
        end
        if $CacheTypes[ccode]
          full_type = $CacheTypes[ccode]
        else
          displayWarning "Cache image code #{ccode.inspect} for type #{full_type.inspect} C - please report!"
          displayInfo "#{line}"
        end
        # there may be more than 1 match, don't overwrite
        cache['type'], full_type = shortenType(full_type)
        if cache['fulltype']
          debug "Not overwriting \"#{cache['fulltype']}\" (#{cache['type']}) with \"#{full_type}\""
        else
          cache['fulltype'] = full_type
        end
        if cache['fulltype'] =~ /Event/
            debug "Setting event flag for #{full_type}"
            cache['event'] = true
        end
        debug "short type=#{cache['type']} for #{full_type}"

        # AFAIK only "user" queries actually return archived caches
        # class="lnk OldWarning Strike Strike"><span>Lars vom Mars</span></a>
        # class="lnk  Strike"><span>Rund um den See, # 04</span></a>
        if strike =~ /class=\"[^\"]*Warning/
          cache['archived'] = true
          debug "#{name} appears to be archived"
#        else
#          cache['archived'] = false
        end

        if strike =~ /class=\"[^\"]*Strike/
          cache['disabled'] = true
          debug "#{name} appears to be disabled"
#        else
#          cache['disabled'] = false
        end

        cache['name'] = name.gsub(/  */, ' ')
        debug "guid=#{cache['guid']} name=#{cache['name']} (disabled=#{cache['disabled']}, archived=#{cache['archived']})"

# 2011-05-04: unchanged
      # by gonsuke@Zerosen and Bakatono@Zerosen
      when /^\s+by (.*?)\s*$/
        creator = $1
        cache['creator'] = creator
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
        debug "Found country \"#{$2}\" state \"#{$3}\""
        if ($3 != "Icons" and $3 != "Placed" and $3 != "Description" and $3 != "Last Found")
          # special case US states:
          #./interface/input.rb:        states = cs.findMatchingState(try_state, '.')
          #./lib/country_state.rb:  def findMatchingState(try_state, country)
          if $2.to_s == ""
            if @cs.findMatchingState($3, 'United States').length != 0
              cache['country'] = 'United States'
              cache['state'] = $3
            else
              cache['country'] = 'Unidentified country'
              cache['state'] = $3
            end
          else
            cache['country'] = $3
            cache['state'] = ($2) ? $2 : 'Unidentified state' # GCStatistic doesn't like empty state elements
          end
          debug "Using country \"#{cache['country']}\" state \"#{cache['state']}\""
        end

      # small_profile.gif" alt="Premium Member Only Cache" with="15" height="13"></TD
      when /Premium Member Only Cache/
        debug "#{wid} is a members only cache. Marking"
        cache['membersonly'] = true

# 2013-05-07: back to the roots
      # <span class="small">1.5/1.5</span><br /><img src="/images/icons/container/micro.gif" alt="Size: Micro" title="Size: Micro" />
      when /^\s+<span[^>]*>([\d.]+)\/([\d.]+)<.*?\/container\/(\w+)\./
        cache['difficulty'] = tohalfint($1)
        cache['terrain'] = tohalfint($2)
        cache['size'] = $3.gsub(/_/, ' ') # "not chosen"
# 2013-08-21: split into multiple lines
      when /^\s+<span[^>]*>([\d.]+)\/([\d.]+)<\/span>/
        cache['difficulty'] = tohalfint($1)
        cache['terrain'] = tohalfint($2)
      when /^\s+<img src.*?\/container\/(\w+)\./
        cache['size'] = $1.gsub(/_/, ' ') # "not chosen"

# 2013-08-21: /geocache/${wid}[_.*] links to new pages
      # <a href="http://www.geocaching.com/geocache/GC42CGC_platz-der-einheit" ...
      when /href=\".*\/geocache\/(GC[A-Z0-9]*)_.*/
        if @widsonly
          wid = $1
          debug "found link to WID #{wid}"
        end

      when /^\s+<\/tr>/
        debug "--- end of row ---"
        if wid and not @waypoints.has_key?(wid)
          debug2 "- closing #{wid} record -"
          waypoints_total += 1
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
        wid = nil

      end # end case

    } # end loop
    rescue => error
      displayWarning "Error in parseSearchData():data.split"
      raise error
    end
    debug2 "processPage done: page:#{page_number} total pages: #{pages_total} parsed: #{waypoints_total}"
    return [page_number, pages_total, waypoints_total, post_vars]
  end #end parsecache

end
