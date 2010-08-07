# $Id$

require 'cgi'
require 'geocode'
require 'shadowget'
require 'time'

BASE_URL = 'http://www.geocaching.com/seek/nearest.aspx'

class SearchCache
  include Common
  include Messages
  
  attr_accessor :distance
    
  def initialize
    @distance = 15
    @ttl = 72000
    @waypoints = Hash.new
  end

  # set the search mode. valid modes are 'zip', 'state', 'country', 'keyword', coord, user
  def setType(mode, key)
    @query_type = nil
    @query_arg = key
    supports_distance = false    
    case mode
    when 'location'
      # Try country/state search, then fall back to geocoding.
      code = SearchCode.new("country")
      @query_arg = code.lookup(key)
      if not @query_arg
        code = SearchCode.new("state")
        @query_arg = code.lookup(key)
      end
     
      if @query_arg
        debug "#{key} was found in #{code.type} database, skipping geocode."
        @query_type = code.type
      else
        @query_type = 'location'
        @query_arg = key
        geocoder = GeoCode.new()
        accuracy, lat, lon = geocoder.lookup(key)
        debug "geocoder returned: a:#{accuracy} x:#{lat} y:#{lon}"
        if not accuracy
          displayWarning "Google Maps failed to determine the location of #{key}"
          return nil
        else
          displayMessage "Google Maps found \"#{key}\". Accuracy level: #{accuracy}"
        end
        @search_url = BASE_URL + "?lat=#{lat}&lng=#{lon}"
        supports_distance = true
      end

    when 'state', 'country'
      code = SearchCode.new(mode)
      @query_type = code.type
      @query_arg = code.lookup(key)

    when 'coord'
      @query_type = 'coord'
      supports_distance = true
      lat_dir, lat_h, lat_ms, long_dir, long_h, long_ms, lat_ns, long_ew = parseCoordinates(key)
      @search_url = BASE_URL + '?lat_ns=' + lat_ns.to_s + '&lat_h=' + lat_h + '&lat_mmss=' + (lat_ms==''?'0':lat_ms) + '&long_ew=' + long_ew.to_s + '&long_h=' + long_h + '&long_mmss=' + (long_ms==''?'0':long_ms)

    when 'user'
      @query_type = 'ul'
      @ttl = 43200

    when 'keyword'
      @query_type = 'key'

    when 'zipcode'
      supports_distance = true
      @query_type = 'zip'

    when 'wid'
      @query_type = 'wid'
      if key =~ /^GC/i
        @search_url = "http://www.geocaching.com/seek/cache_details.aspx?wp=#{key.upcase}"
      else
        displayError "Waypoint ID's must start with GC"
        return nil
      end
    end            

    if not @query_type
      displayWarning "Could not determine what type of query you mean by #{mode}"
      return nil
    end      

    if not @search_url
        @search_url = BASE_URL + '?' + @query_type + '=' + CGI.escape(@query_arg.to_s)
    end
    
    if supports_distance and @distance
        @search_url = @search_url + '&dist=' + @distance.to_s
    end

    displayInfo @search_url
    return @query_type
  end
    
  def parseCoordinates(key)
    # This regular expression should probably handle any kind of messed. Thanks sbrynen!
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
    displayMessage "Coordinate's have been parsed as latitude #{lat_dir} #{lat_h}'#{lat_ms}, longitude #{long_dir} #{long_h}'#{long_ms}"
    coords = [lat_dir, lat_h, lat_ms, long_dir, long_h, long_ms, lat_ns, long_ew]
    return coords
  end    
        
  def getResults()
    if @query_type == 'wid'
      # Yes, we fake it.
      @waypoints[@query_arg] = {
        'visitors' => [],
        'terrain' => 1,
        'difficulty' => 1,
        'mdays' => 1
      }
      return @waypoints
    else
      return searchResults(@search_url)
    end
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
        sleep(20)
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
  
  def fillInFormData(data)
    # Check if the page has a form. If so, fill it in and return new page data.
    province_required = false
    post_vars = Hash.new
    select = nil
    
    data.each_line {|line|
      if line =~ /onsubmit=\"/
        debug "Looks like #{@search_url} requires a State/Province selection."
        province_required = true
      end

      if province_required
        if (line =~ /^\<input type=\"hidden\" name=\"([^\"]*?)\".* value=\"([^\"]*?)\" \/\>/)
          debug "found hidden post variable: #{$1}=#{$2}"
          post_vars[$1] = $2
        end
        if (line =~ /^\<input type=\"submit\" name=\"([^\"]*?)\".* value=\"([^\"]*?)\"/)
          debug "found submit post variable: #{$1}=#{$2}"
          post_vars[$1] = $2
        end
        
        if (line =~ /\<select name=\"([^\"]*?)\"/)
          select = $1
        elsif (line =~ /\<option selected=\"selected\" value=\"([^\"]*?)\"/)
          if select
            debug "found selected option: [" + select + "] #{$1}"
            post_vars[select]=$1
            select = nil
          else
            debug "found selected option: #{$1}"
            displayError "Found selected <option>, but no previous <select> tag."
            return nil
          end
        end
      end
    }
    if province_required
      displayInfo 'Resubmitting search with state/province form data'
      return getPage(@search_url, post_vars)
    else
      return data
    end
  end
      
  def parseSearchData(data)
    page_number = nil
    pages_total = nil
    parsed_total = 0
    wid = nil
    waypoints_total = nil
    @next_page_target = nil
    post_vars = Hash.new
    cache = {}

    data = fillInFormData(data)        
    data.split("\n").each { |line|
      case line
      # <TD class="PageBuilderWidget"><SPAN>Total Records: <B>2938</B> - Page: <B>147</B> of <B>147</B>
      when /Total Records: \<b\>(\d+)\<\/b\> - Page: \<b\>(\d+)\<\/b\> of \<b\>(\d+)\<\/b\>/
        if not waypoints_total
          waypoints_total = $1.to_i
          page_number = $2.to_i
          pages_total = $3.to_i
        end
        # href="javascript:__doPostBack('ctl00$ContentBody$pgrTop$ctl08','')"><b>Next &gt;</b></a></td> 
        # <a href="javascript:__doPostBack('pgrTop$_ctl16','')"><b>Next</b></a>
        if line =~ /doPostBack\(\'([\w\$_]+)\',\'\'\)\"\>\<b\>Next/
          debug "Found next target: #{$1}"
          post_vars['__EVENTTARGET'] = $1
        end

      #<IMG src="./gc_files/8.gif" alt="Unknown Cache" width="32" height="32"></A>
      # <IMG src="./gc_files/21.gif" alt="Travel Bug Dog Tag (1 item)">  </TD>
      when /WptTypes\/[\w].*?alt=\"(.*?)\"/
        # This line also has travel bug data
        full_type = $1
        if line =~ /Travel Bug.*?\((.*?)\)/ 
          debug "Travel Bug Found: #{$1}"
          cache['travelbug']=$1
        else
          debug "type line: #{line}"
        end
        cache['mdays']=-1
        short_type = full_type.split(' ')[0].downcase.gsub(/\-/, '')
        cache['fulltype']=full_type
        cache['type']=short_type
        debug "type=#{cache['type']}"
        
        # This line also has travel bug data
        if line =~ /Travel Bug.*?(\d+) item"/
          debug "Travel Bug Found: #{$1}"
          cache['travelbug']=$1
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
      when /^ (\w+[ \w]+)\**\<[bs][rt]/
        debug "last found date: #{$1} at line: #{line}"
        cache['mtime'] = parseDate($1)
        cache['mdays'] = daysAgo(cache['mtime'])
        debug "mtime=#{cache['mtime']} mdays=#{cache['mdays']}"
        
      #  9 Sep 06
      when /^ +(\d+ \w{3} \d+).*/
        cache['ctime'] = parseDate($1)
        cache['cdays'] = daysAgo(cache['ctime'])
        debug "ctime=#{cache['ctime']} cdays=#{cache['cdays']}"
        
      # <img src="/images/icons/compass/SW.gif" alt="SW" />SW<br />0.9mi</td>
      when /([NWSE]+)\<br \/\>([\d\.]+)mi\</
        cache['distance']=$2.to_f
        cache['direction'] = $1
        debug "cacheDistance=#{cache['distance']} dir=#{cache['direction']}"
      
      # <a href="/seek/cache_details.aspx?guid=c9f28e67-5f18-45c0-90ee-76ec8c57452f">Yasaka-Shrine@Zerosen</a>
      when /cache_details.aspx\?guid=(.*?)\">(.*?)\<\/a\>/
        cache['sid']=$1
        name = $2
        debug "Found cache details link for #{name}"

        if name =~ /class=\"Warning/ or name =~ /class=\"OldWarning/
          cache['archived']=1
          debug "#{name} appears to be archived"
        end

        if name =~ /Strike"\>(.*?)\<\//
          cache['disabled']=1
          debug "#{name} appears to be disabled"
          name=$1
        else
          cache['disabled']=nil
        end

        cache['name']=name.gsub(/ +$/, '')
        debug "sid=#{cache['sid']} name=#{cache['name']} (disabled=#{cache['disabled']}, archived=#{cache['archived']})"

      # by gonsuke@Zerosen and Bakatono@Zerosen
      when /^ +by (.*?)$/
        creator = $1
        cache['creator'] = creator.gsub(/\s+$/, '')
        debug "creator=#{cache['creator']}"
      
      # (GC1Z0RT)<br />
      when /^ +\((GC.*?)\)\<br \/\>/
        wid = $1
        debug "wid=#{wid}"

      # small_profile.gif" alt="Premium Member Only Cache" with="15" height="13"></TD
      when /Premium Member Only Cache/
        debug "Found members only cache. Marking"
        cache['membersonly'] = 1
                                  
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