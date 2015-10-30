#!/usr/bin/env ruby

#
# This is the main geotoad binary.
#

require 'pathname'
$BASEDIR = File.dirname(File.realpath(__FILE__))
$LOAD_PATH << $BASEDIR
$LOAD_PATH << File.join($BASEDIR, 'lib')

Encoding.default_external = Encoding::UTF_8

$delimiters = /[\|:]/
$delimiter = '|'

$my_lat = nil
$my_lon = nil

# toss in our own libraries.
require 'interface/progressbar'
require 'lib/common'
require 'lib/messages'
require 'interface/input'
require 'lib/shadowget'
require 'lib/search'
require 'lib/filter'
require 'lib/output'
require 'lib/details'
require 'lib/auth'
require 'lib/version'
require 'getoptlong'
require 'fileutils'
require 'find' # for cleanup
require 'zlib'
require 'cgi'
require 'net/https' # for openssl

class GeoToad

  include Common
  include Messages
  include Auth
  $VERSION = GTVersion.version
  # with the new progressive slowdown, start with 1 second
  $SLEEP = 1.0

  # *if* cache D/T/S extraction works, early filtering is possible
  $DTSFILTER = true

  # time to use for "unknown" creation dates
  $ZEROTIME = 946728000 # 2000-01-01T13:00:00Z

  # conversion miles to kilometres
  $MILE2KM = 1.609344

  def initialize
    $debugMode    = 0
#    output        = Output.new
#    $validFormats = output.formatList.sort
    @uin          = Input.new
    $CACHE_DIR    = findCacheDir()
    @configDir    = findConfigDir
#    $mapping      = loadMapping()
    $membership   = nil # unknown before searching
  end

  def populate
    output        = Output.new
    $validFormats = output.formatList.sort
    $mapping      = loadMapping()
  end

  def caches(num, what = "cache", length = 4)
    if (num > 0)
      counter = "#{num.to_s}"
    else
      counter = "no"
    end
    return "#{counter.rjust(length)} #{what}" + ((num != 1) ? 's' : '')
  end

  def getoptions
    if ARGV[0]
      # command line arguments
      @option = @uin.getopt
      $mode = 'CLI'
    else
      # Then go into interactive.
      print "** Press Enter to start the Text User Interface: "
      $stdin.gets
      @option = @uin.interactive
      $mode = 'TUI'
    end

    # if version info requested, skip other checks
    if @option['version']
      return @option
    end

    # enable synchronous output if selected by user
    if (@option['unbufferedOutput'])
      if (! $stdout.sync)
        $stdout.flush
        $stdout.sync = true
        puts "(***) Switched to unbuffered output"
      end
    end

    # may be nil, a number, or "something non-nil" (=1)
    if (@option['verbose'])
      if (@option['verbose'].to_i > 0)
        displayInfo "Setting debug level to #{@option['verbose']}"
        enableDebug(@option['verbose'].to_i)
      else
        displayInfo "Setting debug level to 1"
        enableDebug
      end
    else
      debug "Suppressing debug output"
      disableDebug
    end

    if @option['proxy']
      ENV['HTTP_PROXY'] = @option['proxy']
    end

    # We need this for the check following
    @queryType         = @option['queryType'] || 'location'
    @queryArg          = @option['queryArg'] || nil

    # Get this out of the way now.
    if @option['help']
      @uin.usage
      exit
    end

    if ! @option['clearCache'] && ! @option['myLogs'] && ! @option['myTrackables'] && ! @queryArg
      displayError "You forgot to specify a #{@queryType} search argument"
      @uin.usage
      exit
    end

    if (! @option['user']) || (! @option['password'])
      debug "No user/password option given, loading from config."
      (@option['user'], @option['password']) = @uin.loadUserAndPasswordFromConfig()
      if (! @option['user']) || (! @option['password'])
        displayError "You must specify a username and password!"
        exit
      end
    end

    # switch -X to disable early DTS filtering
    if (@option['disableEarlyFilter'])
      $DTSFILTER = false
    end

    @preserveCache     = @option['preserveCache']

    @formatTypes       = @option['format'] || 'gpx'
    # there is no "usemetric" cmdline option but the TUI may set it
    @useMetric         = @option['usemetric']
    # distanceMax from command line can contain the unit
    @distanceMax       = @option['distanceMax'].to_f
    if @distanceMax == 0.0
      @distanceMax = 10
    end
    if @option['distanceMax'] =~ /(mi|km)/
      @useMetric     = ($1 == "km" || nil)
      # else leave usemetric unchanged
    end
    if @useMetric
      # convert to miles, round to multiple of ~.5ft
      @distanceMax     = sprintf("%.4f", @distanceMax / $MILE2KM).to_f
    end
    debug "Internally using distance #{@distanceMax} miles."
    # include query type, will be parsed by output.rb
    @queryTitle        = "GeoToad: #{@queryType} = #{@queryArg}"
    @defaultOutputFile = "gt_" + @queryArg.to_s
    # collect additional title and output filename text
    # key: short option
    # 'f': filename << "#{key}#{h['f']}"
    # 't': title << "#{h['t']} #{h['f']}"}"
    @appliedFilters    = Hash.new

    # No early format validity check

    @limitPages = @option['limitSearchPages'].to_i
    debug "Limiting search to #{@limitPages.inspect} pages" if (@limitPages != 0)

    return @option
  end

  ## Check the version #######################
  def comparableVersion(text)
    # Make a calculatable/comparable version number
    parts = text.split('.')
    version = (parts[0].to_i * 10000) + (parts[1].to_i * 100) + parts[2].to_i
    return version
  end

  def versionCheck

    checkurl = "https://raw.githubusercontent.com/wiki/steve8x8/geotoad/CurrentVersion.md"
    wikiurl = "https://github.com/steve8x8/geotoad/wiki/CurrentVersion"

    version = ShadowFetch.new(checkurl)
    version.localExpiry = 1 * 86400	# 1 day
    version.maxFailures = 0
    version.fetch

    # version=a.bb.cc[*] in wiki page (* marks "supersedes all")
    if version.data =~ /version=(\d\.\d+[\.\d]+)(\*)?/
      latestVersion = $1
      obsoleteOlder = ! $2.to_s.empty?

      if comparableVersion(latestVersion) > comparableVersion($VERSION)
        displayBar
        displayWarning "VersionCheck: GeoToad #{latestVersion} is now available!"
        displayBar
        version.data.scan(/version=\S*\s*(.*?)\s*---/im) do |notes|
          text = notes[0].dup
          text.gsub!(/^#\s/, "\n\* ")
          text.gsub!(/^##\s/, "\n\+ ")
          text.gsub!(/^###\s/, "\n\- ")
          text.gsub!(/#+$/, "")
          text.gsub!(/\n\n+/, "\n")
          text.gsub!(/\&nbsp;/, '-')
          textlines = text.split("\n")
          (1..20).each{ |line|
            displayBox textlines[line] if textlines[line]
          }
          displayBox "... see #{wikiurl} for more" if textlines.length > 20
          if obsoleteOlder
            displayBar
            displayWarning "Older versions do not work any longer. Update NOW!"
            displayBar
          end
        end
        displayBar
        if $VERSION !~ /CURRENT/
          displayInfo "(sleeping for 30 seconds)"
          sleep(30)
        end
      end
    end
    debug "Check complete."
  end

  def findRemoveFiles(where, age, pattern = ".*\\..*", writable = nil)
  # inspired by ruby-forum.com/topic/149925
    regexp = Regexp.compile(pattern)
    debug "findRemoveFiles() age=#{age}, pattern=#{pattern}, writable=#{writable.inspect}"
    filelist = Array.new
    begin # catch filesystem problems
      Find.find(where){ |file|
        # never touch directories
        next if not File.file?(file)
        next if (age * 86400) > (Time.now - File.mtime(file)).to_i
        next if not regexp.match(File.basename(file))
        next if writable and not File.writable?(file)
        filelist.push file
      }
    rescue => error
      displayWarning "Cannot parse #{where}: #{error}"
      return
    end
    filecount = filelist.length
    debug2 "found #{filecount} files to remove: #{filelist.inspect}"
    if not filelist.empty?
      displayInfo "... #{filecount} files to remove"
      filelist.each{ |file|
        begin
          File.delete(file)
        rescue => error
          displayWarning "Cannot delete #{file}: #{error}"
        end
      }
    end
  end

  def clearCacheDirectory
    displayMessage "Clearing #{$CACHE_DIR} selectively"

    displayInfo "Clearing account data older than 7 days"
    findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "account"), 7)
    # obsolete again 2014-10-28
    #findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "myaccount"), 7)

    displayInfo "Clearing login data older than 7 days"
    findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "login"), 7)

    # We do NOT clear cdpf files, in NO case. Instead, preserve old descriptions!
    # If you really want this functionality, uncomment the following two lines:
    #displayInfo "Clearing cache descriptions older than 31 days"
    #findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "seek"), 31, "^cdpf\\.aspx.*", true)

    displayInfo "Clearing cache details older than 3 days"
    findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "seek"), 3, "^cache_details\\.aspx.*", true)

    displayInfo "Clearing lat/lon query data older than 3 days"
    findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "seek"), 3, "^nearest\\.aspx.*_lat_.*_lng_.*", true)

    displayInfo "Clearing state and country query data older than 3 days"
    findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "seek"), 3, "^nearest\\.aspx.*_(country|state)_id_.*", true)

    displayInfo "Clearing other query data older than 7 days"
    findRemoveFiles(File.join($CACHE_DIR, "www.geocaching.com", "seek"), 7, "^nearest\\.aspx.*", true)

    displayMessage "Cleared!"
    $CACHE_DIR = findCacheDir()
  end

  ## Make the Initial Query ############################
  def downloadGeocacheList
    displayInfo "Cache directory: " + $CACHE_DIR

    # Mike Capito contributed a patch to allow for multiple
    # queries. He did it as a hash earlier, I'm just simplifying
    # and making it as an array because you probably don't want to
    # mix multiple @queryType's anyways
    @combinedWaypoints = Hash.new

    displayMessage "Logging in as #{@option['user']}"
    @cookie = login(@option['user'], @option['password'])
    debug "Login returned cookie #{hideCookie(@cookie).inspect}"
    if (@cookie)
      displayMessage "Login successful"
    else
      displayWarning "Login failed! Check network connection, username and password!"
      displayWarning "Note: Subsequent operations may fail. You've been warned."
    end
    displayMessage "Querying user preferences"
    @dateFormat, prefLang, $my_lat, $my_lon, $my_src = getPreferences()
    displayInfo "Using date format #{@dateFormat}, language #{prefLang}"
    displayInfo "Using home location (#{$my_lat || 'nil'}, #{$my_lon || 'nil'}) from #{$my_src}"

    if @option['myLogs'] || @option['myTrackables']
      displayMessage "Retrieving my logs"
      message = ""
      if @option['myLogs']
        foundcount, logcount = getMyLogs()
        message << "Found count: #{foundcount}. "
        message << "Cache logs: #{logcount}. "
      end
      if @option['myTrackables']
        logcount = getMyTrks()
        message << "Trackable logs: #{logcount}."
      end
      displayInfo message
    end

    # search radius applies to all queryArgs, show only once
    if @queryType == 'location' || @queryType == 'coord'
      # choose correct unit for query title and output filename
      # strip off trailing 0's and period
      # keep information close to the query location
      if @useMetric
        dist_km = sprintf("%.3f", @distanceMax * $MILE2KM).gsub(/\.?0*$/, '')
        @queryTitle << " (#{dist_km} km radius)"
        @defaultOutputFile << "-y#{dist_km}km"
      else
        dist_mi = sprintf("%.3f", @distanceMax).gsub(/\.?0*$/, '')
        @queryTitle << " (#{@distanceMax} mi radius)"
        @defaultOutputFile << "-y#{dist_mi}"
      end
    end

    @queryArg.to_s.split($delimiters).each{ |queryArg0|
      puts ""
      queryArg = queryArg0.gsub(/^\s+/, '').gsub(/\s+$/, '')
      message = "\"#{@queryType}\" search for \"#{queryArg}\""
      search = SearchCache.new

      # radius is only valid for location or coordinate searches
      if @queryType == 'location' || @queryType == 'coord'
        message << ", constraining to "
        if @useMetric
          message << "#{dist_km} km"
        else
          message << "#{dist_mi} miles"
        end
        search.distance = @distanceMax
      end

      # limit search page count
      search.max_pages = @limitPages

      if @option['cacheType']
        # filter by cacheType
        cacheTypes = @option['cacheType'].split($delimiters)
        cacheType0 = cacheTypes[0]
        if (cacheTypes.length == 1)
          # inverted filter? careful...
          if (cacheType0 !~ /-$/)
            # if only one type, use tx= parameter (pre-filtering)
            message << ", filter for \"#{cacheType0}\""
            search.txfilter = cacheType0
          end
          # otherwise, warn if "all xxx" is in the list
        elsif cacheTypes.map{ |t| (t =~ /\+$/) ? "x" : nil }.any?
          displayWarning "\"all\" only works as single cache type - your results will be wrong!"
          sleep 10
        end
      end
      displayMessage message

      # exclude own found
      search.notyetfound = (@option['notFoundByMe'] ? true : false)

      # this is kind of late, but we did our best 
      # we had to set txfilter and notyetfound before because setType creates the search URL
      if (! search.setType(@queryType, queryArg))
        displayWarning "Search \"#{@queryType}\" for \"#{queryArg}\" unknown."
        displayWarning "Check for special characters or try a \"coord\" search instead."
        sleep 10
        next
      end

      waypoints = search.getResults()
      # this gives us support for multiple searches. It adds together the search.waypoints hashes
      # and pops them into the @combinedWaypoints hash.
      @combinedWaypoints.update(waypoints)
      @combinedWaypoints.rehash
    }

    # Here we make sure that the amount of waypoints we've downloaded (@combinedWaypoints) matches the
    # amount of waypoints we found information for. This is just to check for buggy search code, and
    # really doesn't make much sense.

    waypointsExtracted = 0
    @combinedWaypoints.each_key{ |wp|
      debug2 "pre-filter: #{wp}"
      waypointsExtracted = waypointsExtracted + 1
    }

    debug "waypoints extracted: #{waypointsExtracted}, combined: #{@combinedWaypoints.length}"
    if (waypointsExtracted < @combinedWaypoints.length)
      displayWarning "Downloaded #{@combinedWaypoints.length} waypoints, but only #{waypointsExtracted} parsed!"
    end
    puts ""
    return waypointsExtracted
  end


  def prepareFilter
    # Prepare for the manipulation
    @filtered = Filter.new(@combinedWaypoints)

    if @option['notFoundByMe']
      @appliedFilters['-N'] = { 'f' => "", 't' => "not done by #{@option['user']}" }
    end

    # This is where we do a little bit of cheating. In order to avoid downloading the
    # cache details for each cache to see if it's been visited, we do a search for the
    # users on the include or exclude list. We then populate @combinedWaypoints[wid]['visitors']
    # with our discovery.

    userLookups = Array.new
    if @option['userExclude'] and not @option['userExclude'].empty?
      @appliedFilters['-E'] = { 'f' => "#{@option['userExclude']}", 't' => "not done by" }
      userLookups = @option['userExclude'].split($delimiters)
    end

    if @option['userInclude'] and not @option['userInclude'].empty?
      @appliedFilters['-e'] = { 'f' => "#{@option['userInclude']}", 't' => "done by" }
      userLookups = userLookups + @option['userInclude'].split($delimiters)
    end

    userLookups.each{ |user|
      # issue 236: if "user" is file, read that
      if (user =~ /(.*)=(.*)/)
        username = $1
        filename = $2
        puts ""
        displayMessage "Read #{filename} for #{username}"
        counter = 0
        # read file (1st column)
        begin
          File.foreach(filename){ |line|
          if (line =~ /^(GC\w+)/i)
            wid = $1
            debug2 "Add #{wid} for #{username}"
            @filtered.addVisitor(wid, username)
            counter = counter + 1
          end
          }
          displayInfo "Total of #{counter} WIDs read"
        rescue
          displayWarning "Problems reading #{filename} for #{username}"
        end
      else
        search = SearchCache.new
        search.setType('user', user)
        waypoints = search.getResults()
        waypoints.keys.each{ |wid|
          @filtered.addVisitor(wid, user)
        }
      end
    }
  end


  def showRemoved(count, text)
    if (count > 0)
      text10 = text.ljust(10)
      displayMessage "#{text10} filtering removed #{caches(count)}."
    end
  end

  ## step #1 in filtering! ############################
  # This step filters out all the geocaches by information
  # found from the searches.
  def preFetchFilter
    puts ""
    @filtered = Filter.new(@combinedWaypoints)
    debug "Filter running cycle 1, #{caches(@filtered.totalWaypoints)} left."

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['cacheType']
      # post-filter by cacheType
      @appliedFilters['-c'] = { 'f' => "#{@option['cacheType']}", 't' => "type" }
      if @option['cacheType'] !~ /\+$/
        # but only if there's no "all xxx" chosen
        @filtered.cacheType(@option['cacheType'])
      else
        displayWarning "Not filtering for cache type!"
      end
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Cache type")

    # exclude Premium Member Only caches on request
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['noPMO']
      @filtered.removeByElement('membersonly')
    end
    # may not be accurate before fetching details?
    if @option['onlyPMO']
      @filtered.removeByElement('membersonly', false)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "PM-Only")

    if $DTSFILTER
    #-------------------
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['difficultyMin']
      @appliedFilters['-d'] = { 'f' => "#{@option['difficultyMin']}", 't' => "difficulty min" }
      @filtered.difficultyMin(@option['difficultyMin'].to_f)
    end
    if @option['difficultyMax']
      @appliedFilters['-D'] = { 'f' => "#{@option['difficultyMax']}", 't' => "difficulty max" }
      @filtered.difficultyMax(@option['difficultyMax'].to_f)
    end
    if @option['terrainMin']
      @appliedFilters['-t'] = { 'f' => "#{@option['terrainMin']}", 't' => "terrain min" }
      @filtered.terrainMin(@option['terrainMin'].to_f)
    end
    if @option['terrainMax']
      @appliedFilters['-T'] = { 'f' => "#{@option['terrainMax']}", 't' => "terrain max" }
      @filtered.terrainMax(@option['terrainMax'].to_f)
    end
    if @option['sizeMin']
      @appliedFilters['-s'] = { 'f' => "#{@option['sizeMin']}", 't' => "size min" }
      @filtered.sizeMin(@option['sizeMin'])
    end
    if @option['sizeMax']
      @appliedFilters['-S'] = { 'f' => "#{@option['sizeMax']}", 't' => "size max" }
      @filtered.sizeMax(@option['sizeMax'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "D/T/Size")
    #-------------------
    end # $DTSFILTER

    debug "Filter running cycle 2, #{caches(@filtered.totalWaypoints)} left."

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['foundDateInclude']
      @appliedFilters['-r'] = { 'f' => "#{@option['foundDateInclude']}", 't' => "found age max" }
      @filtered.foundDateInclude(@option['foundDateInclude'].to_f)
    end
    if @option['foundDateExclude']
      @appliedFilters['-R'] = { 'f' => "#{@option['foundDateExclude']}", 't' => "found age min" }
      @filtered.foundDateExclude(@option['foundDateExclude'].to_f)
    end
    if @option['placeDateInclude']
      @appliedFilters['-j'] = { 'f' => "#{@option['placeDateInclude']}", 't' => "cache age max" }
      @filtered.placeDateInclude(@option['placeDateInclude'].to_f)
    end
    if @option['placeDateExclude']
      @appliedFilters['-J'] = { 'f' => "#{@option['placeDateExclude']}", 't' => "cache age min" }
      @filtered.placeDateExclude(@option['placeDateExclude'].to_f)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Date")

    debug "Filter running cycle 3, #{caches(@filtered.totalWaypoints)} left."

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['notFound']
      @appliedFilters['-n'] = { 'f' => "", 't' => "virgins" }
      @filtered.notFound
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Unfound")

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['travelBug']
      @appliedFilters['-b'] = { 'f' => "", 't' => "trackables" }
      @filtered.travelBug
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Trackable")

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['ownerExclude'])
      @appliedFilters['-I'] = { 'f' => "#{@option['ownerExclude']}", 't' => "not owned by" }
      @option['ownerExclude'].split($delimiters).each{ |owner|
        @filtered.ownerExclude(owner)
      }
    end
    if (@option['ownerInclude'])
      @appliedFilters['-i'] = { 'f' => "#{@option['ownerInclude']}", 't' => "owned by" }
      @option['ownerInclude'].split($delimiters).each{ |owner|
        @filtered.ownerInclude(owner)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Owner")

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['userExclude'])
      @appliedFilters['-E'] = { 'f' => "#{@option['userExclude']}", 't' => "not done by" }
      @option['userExclude'].split($delimiters).each{ |user|
        @filtered.userExclude(user)
      }
    end
    if (@option['userInclude'])
      @appliedFilters['-e'] = { 'f' => "#{@option['userInclude']}", 't' => "done by" }
      @option['userInclude'].split($delimiters).each{ |user|
        @filtered.userInclude(user)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "User")

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['titleKeyword']
      @appliedFilters['-k'] = { 'f' => "#{@option['titleKeyword']}", 't' => "matching title keyword" }
      @filtered.titleKeyword(@option['titleKeyword'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Title")

    displayMessage "Pre-fetch  filter  complete, #{caches(@filtered.totalWaypoints)} left."
  end


  def copyGeocaches
    # don't load details, just copy from search results
    wpFiltered = @filtered.waypoints
    @detail = CacheDetails.new(wpFiltered)
  end

  def fetchGeocaches
    puts ""
    if $membership
      displayMessage "Fetching geocache pages as \"#{$membership}\""
    else
      displayMessage "Fetching geocache pages"
    end
    wpFiltered = @filtered.waypoints
    progress = ProgressBar.new(0, @filtered.totalWaypoints, "")
    @detail = CacheDetails.new(wpFiltered)
    @detail.preserve = @preserveCache
    token = 0

    wpFiltered.each_key{ |wid|
      token = token + 1
      detailURL = @detail.fullURL(wid)
      page = ShadowFetch.new(detailURL)
      status = @detail.fetch(wid)
      message = nil

      if status == 'login-required'
        displayMessage "Cookie does not appear to be valid, logging in as #{@option['user']}"
        @detail.cookie = login(@option['user'], @option['password'])
        status = @detail.fetch(wid)
      end

      if status == 'subscriber-only'
        message = '(subscriber-only)'
      elsif status == 'unpublished'
        wpFiltered.delete(wid)
        displayWarning "#{wid} is either unpublished or hidden subscriber-only, skipping."
        next
      elsif ! status or status == 'login-required'
        if (wpFiltered[wid]['warning'])
          debug "Could not parse page, but it had a warning, so I am not invalidating"
          message = "(PMO? #{wpFiltered[wid]['warning'].inspect})"
        else
          # don't throw this out yet, will get null entries in output though
          message = "(PMO? #{status.to_s.inspect})"
        end
      else
        # PMonly caches: write specific message
        if (wpFiltered[wid]['membersonly'])
          message = "[PMO]"
        # unspecific error message
        elsif (wpFiltered[wid]['warning'])
          message = "(unavailable)"
        end
      end
      name = wpFiltered[wid]['name']
      # remove HTML cruft from name, may fail in rare cases (emoji)
      begin
        temp = CGI::unescapeHTML(name)
      rescue
        temp = name.gsub(/\&/, '+')
      end
      name = temp
      progress.updateText(token, "[#{wid}]".ljust(9)+" \"#{name}\" (#{page.src.gsub(/(\w)\w*/){$1}}) #{message}")

      if status == 'subscriber-only'
        wpFiltered.delete(wid)
      end

      if message == '(error)'
        debug "Page for #{wpFiltered[wid]['name']} failed to be parsed, invalidating cache."
        wpFiltered.delete(wid)
        page.invalidate()
      end
    }
  end

  ## step #2 in filtering! ############################
  # In this stage, we actually have to download all the information on the caches in order to decide
  # whether or not they are keepers.
  def postFetchFilter
    puts ""
    @filtered= Filter.new(@detail.waypoints)

    # caches with warnings we choose not to include.
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['includeDisabled']
      @appliedFilters['-z'] = { 'f' => "", 't' => "also disabled" }
    else
      @appliedFilters['+z'] = { 'f' => "", 't' => "not disabled" }
      @filtered.removeByElement('disabled')
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Disabled")

    # exclude Premium Member Only caches on request
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['noPMO']
      @appliedFilters['-O'] = { 'f' => "", 't' => "no PMO" }
      @filtered.removeByElement('membersonly')
    end
    if @option['onlyPMO']
      @appliedFilters['-Q'] = { 'f' => "", 't' => "PMO" }
      @filtered.removeByElement('membersonly', false)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "PM-Only")

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['descKeyword']
      @appliedFilters['-K'] = { 'f' => "#{@option['descKeyword']}", 't' => "matching descr. keyword" }
      @filtered.descKeyword(@option['descKeyword'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Keyword")

    ##if not $DTSFILTER
    #-------------------
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['difficultyMin']
      @appliedFilters['-d'] = { 'f' => "#{@option['difficultyMin']}", 't' => "difficulty min" }
      @filtered.difficultyMin(@option['difficultyMin'].to_f)
    end
    if @option['difficultyMax']
      @appliedFilters['-D'] = { 'f' => "#{@option['difficultyMax']}", 't' => "difficulty max" }
      @filtered.difficultyMax(@option['difficultyMax'].to_f)
    end
    if @option['terrainMin']
      @appliedFilters['-t'] = { 'f' => "#{@option['terrainMin']}", 't' => "terrain min" }
      @filtered.terrainMin(@option['terrainMin'].to_f)
    end
    if @option['terrainMax']
      @appliedFilters['-T'] = { 'f' => "#{@option['terrainMax']}", 't' => "terrain max" }
      @filtered.terrainMax(@option['terrainMax'].to_f)
    end
    if @option['sizeMin']
      @appliedFilters['-s'] = { 'f' => "#{@option['sizeMin']}", 't' => "size min" }
      @filtered.sizeMin(@option['sizeMin'])
    end
    if @option['sizeMax']
      @appliedFilters['-S'] = { 'f' => "#{@option['sizeMax']}", 't' => "size max" }
      @filtered.sizeMax(@option['sizeMax'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "D/T/Size")
    #-------------------
    ##end # not $DTSFILTER

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['favFactorMin']
      @appliedFilters['-g'] = { 'f' => "#{@option['favFactorMin']}", 't' => "favFactor min" }
      @filtered.favFactorMin(@option['favFactorMin'].to_f)
    end
    if @option['favFactorMax']
      @appliedFilters['-G'] = { 'f' => "#{@option['favFactorMax']}", 't' => "favFactor max" }
      @filtered.favFactorMax(@option['favFactorMax'].to_f)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "FavFactor")

    # We filter for users again. While this may be a bit obsessive, this is in case
    # our local cache is not valid.
    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['userExclude'])
      @appliedFilters['-E'] = { 'f' => "#{@option['userExclude']}", 't' => "not done by" }
      @option['userExclude'].split($delimiters).each{ |user|
        @filtered.userExclude(user)
      }
    end
    if (@option['userInclude'])
      @appliedFilters['-e'] = { 'f' => "#{@option['userInclude']}", 't' => "done by" }
      @option['userInclude'].split($delimiters).each{ |user|
        @filtered.userInclude(user)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "User")

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['attributeExclude'])
      @appliedFilters['-A'] = { 'f' => "#{@option['attributeExclude']}", 't' => "attr no" }
      @option['attributeExclude'].split($delimiters).each{ |attribute|
        @filtered.attributeExclude(attribute)
      }
    end
    if (@option['attributeInclude'])
      @appliedFilters['-a'] = { 'f' => "#{@option['attributeExclude']}", 't' => "attr yes" }
      @option['attributeInclude'].split($delimiters).each{ |attribute|
        @filtered.attributeInclude(attribute)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Attribute")

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['minLongitude'])
      @appliedFilters['--minLon'] = { 'f' => "#{@option['minLongitude']}", 't' => "West" }
      @filtered.longMin(@option['minLongitude'])
    end
    if (@option['maxLongitude'])
      @appliedFilters['--maxLon'] = { 'f' => "#{@option['maxLongitude']}", 't' => "East" }
      @filtered.longMax(@option['maxLongitude'])
    end
    if (@option['minLatitude'])
      @appliedFilters['--minLat'] = { 'f' => "#{@option['minLatitude']}", 't' => "South" }
      @filtered.latMin(@option['minLatitude'])
    end
    if (@option['maxLatitude'])
      @appliedFilters['--maxLat'] = { 'f' => "#{@option['maxLatitude']}", 't' => "North" }
      @filtered.latMax(@option['maxLatitude'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    showRemoved(excludedFilterTotal, "Lat/Lon")

    displayMessage "Post-fetch filter  complete, #{caches(@filtered.totalWaypoints)} left."
    return @filtered.totalWaypoints
  end



  ## save the file #############################################
  def saveFile
    puts ""
    formatTypeCounter = 0

    # @appliedFilters: sort by option letter, ignore case
    debug3 "appliedFilters: #{@appliedFilters.inspect}"
    queryTitleAdd = @appliedFilters.sort{ |a,b|
      a.join.upcase <=> b.join.upcase
    }.map{ |k,v|
      v['t'] + (v['f'].empty? ? "": " #{v['f']}")
    }.join(', ')
    debug "title+ #{queryTitleAdd}"
    @queryTitle << '; ' + queryTitleAdd
    defaultOutputFileAdd = @appliedFilters.sort{ |a,b|
      a.join.upcase <=> b.join.upcase
    }.map{ |k,v|
      (k =~ /^-/) ? "#{k}#{v['f']}" : ""
    }.join
    debug "fname+ #{defaultOutputFileAdd}"
    @defaultOutputFile << defaultOutputFileAdd

    # 'output' may be a directory, with or without trailing slash (should exist)
    # if there's nil or empty (no path at all), use current working directory
    # or the filename for the first output file, explicitly given
    if ! @option['output'].to_s.empty?
      filename = @option['output'].dup
    else
      filename = Dir.pwd
    end
    filename.gsub!('\\', '/')
    # if it's a directory, append a slash just in case
    if File.directory?(filename)
      filename = File.join(filename, '')
    end
    message = "Pattern:  #{filename}"
    # we can now check for a trailing slash safely
    if filename =~ /\/$/
      # automatic mode
      outputDir = filename
      outputFileBase = nil
      message << " (automatic)"
      # flag as automatic for suffixing
      @option['output'] = nil
      outputFileBase = @defaultOutputFile.gsub(/[^0-9A-Za-z\.-]/, '_')
      outputFileBase.gsub!(/_+/, '_')
      # shorten at a somewhat randomly chosen place to fit in filesystem
      if outputFileBase.length > 220
        outputFileBase = outputFileBase[0..215] + "_etc"
      end
    else
      outputFileBase = File.basename(filename)
      # 
      outputDir = File.dirname(filename + 'x')
    end
    displayInfo message
    debug "Using output #{outputDir}/#{outputFileBase}"
    # loop over all chosen formats
    @formatTypes.split($delimiters).each{ |formatType0|
      # does the formatType string contain a "="?
      formatType = formatType0.split(/=/)[0]
      if ! $validFormats.include?(formatType)
        displayWarning "#{formatType} is not a valid supported format - skipping."
        next
      end
      output = Output.new
      displayInfo "Format:   #{output.formatDesc(formatType)} (#{formatType})"
      output.input(@filtered.waypoints)
      output.formatType = formatType
      if (@option['waypointLength'])
        output.waypointLength=@option['waypointLength'].to_i
      end
      if (@option['logCount'])
        output.commentLimit=@option['logCount'].to_i
      end
      # keep filename if first run and not automatic
      # strip suffix only on subsequent runs
      if (formatTypeCounter > 0)
        outputFileBase.gsub!(/\.[^\.]*$/, '')
      end
      # append suffix if automatic or subsequent runs
      if (not @option['output']) || (formatTypeCounter > 0)
        outputFileExt = output.formatExtension(formatType)
        # override default extension?
        if formatType0 =~ /=/
          outputFileExt = formatType0.split(/=/)[1]
        end
        outputFileBase = outputFileBase + "." + outputFileExt
      end
      outputFile = File.join(outputDir, outputFileBase)
      # Lets not mix and match DOS and UNIX /'s, we'll just make everyone like us!
      outputFile.gsub!(/\\/, '/')
      displayInfo "Filename: #{outputFile}"

      # append time to our title
      queryTitle = @queryTitle + " (" + Time.now.strftime("%d%b%y %H:%M") + ")"

      # and do the dirty.
      output.prepare(queryTitle, @option['user'])
      if output.commit(outputFile)
        displayMessage "Saved #{outputFile}"
      else
        displayWarning "NOT saved #{outputFile}!"
      end
      puts ""

      formatTypeCounter += 1
    } # end format loop
  end

end

# for Ocra build
exit if Object.const_defined?(:Ocra)

###### MAIN ACTIVITY ###############################################################
# have some output before initializing the GeoToad, Output, Template classes
include Messages
displayTitle "GeoToad #{$VERSION} (Ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}/#{RUBY_RELEASE_DATE} on #{RUBY_PLATFORM})"

# check Ruby version
if RUBY_VERSION.gsub('.', '').to_i < 191
  displayError "Ruby version is #{RUBY_VERSION}. Required: 1.9.1 or higher."
end
if RUBY_VERSION.gsub('.', '').to_i < 215
  displayWarning "Ruby version is #{RUBY_VERSION}. Recommended: 2.1.5 or higher."
end

# do some SSL initialisation
$SSLVERIFYMODE = OpenSSL::SSL::VERIFY_PEER
# work around (only?) Windows not being able to verify peer
# http://stackoverflow.com/questions/170956/how-can-i-find-which-operating-system-my-ruby-program-is-running-on
# better use RbConfig::CONFIG['host_os']?
if RUBY_PLATFORM.downcase =~ /djgpp|(cyg|ms|bcc)win|mingw|wince|emx/
  displayWarning "HTTPS will not verify peer identity!"
  $SSLVERIFYMODE = OpenSSL::SSL::VERIFY_NONE
end
# apparently there are still old Rubies around which would crash with TLSv1_2
$SSLVERSION = :TLSv1_2
begin
  OpenSSL::SSL::SSLContext.new($SSLVERSION)
rescue => e
  displayWarning "HTTPS #{e}:\n\tfalling back to insecure TLSv1!"
  $SSLVERSION = :TLSv1
end
# if there's no TLSv1 there's no hope
begin
  OpenSSL::SSL::SSLContext.new($SSLVERSION)
rescue => e
  displayError "HTTPS error: #{e}\n\tyour Ruby version does not support TLS!"
end
displayInfo "Using #{$SSLVERSION.to_s} and #{($SSLVERIFYMODE == OpenSSL::SSL::VERIFY_PEER) ? '' : 'no '}SSL verification."

# initialize method: 1st part of init
cli = GeoToad.new
cli.versionCheck

loopcount = 0
while true
  options = cli.getoptions
  if options['clearCache']
    cli.clearCacheDirectory()
    exit
  end
  if options['version']
    # version information has been shown above
    exit
  end

  if (loopcount == 0) # do only once, like before
    if ($VERSION.to_i > 0)
      displayInfo "Thank you for using a released version of GeoToad."
      displayInfo "Report bugs or suggestions at https://github.com/steve8x8/geotoad/"
    else
      displayInfo "You are not using a released version of GeoToad!"
      displayInfo "Report bugs or suggestions to steve8x8 at googlemail.com only."
    end
    displayInfo "Please include verbose output (-v) without passwords in the bug report."
    displayBar

    # second part of initialize
    cli.populate

    displayBar

    loopcount = loopcount + 1
  end

  count = 0
  if options['queryArg'] || options['myLogs'] || options['myTrackables']
    count = cli.downloadGeocacheList()
  end
  if count < 1
    cli.displayWarning "No valid query or no caches found in search, exiting early."
  else
    cli.displayMessage "Your \"#{options['queryType']}\" query \"#{options['queryArg']}\" returned #{cli.caches(count)}."
    cli.prepareFilter
    cli.preFetchFilter

    if options['noCacheDescriptions']
      cli.displayMessage "Skipping retrieval of cache descriptions."
      cli.copyGeocaches
    else
      cli.fetchGeocaches
    end
    caches = cli.postFetchFilter
    if caches > 0
      cli.saveFile
    else
      cli.displayMessage "After filtering, no caches are left matching your requirements."
    end
  end

  # Don't loop if you're in automatic mode.
  if ($mode == "TUI")
    puts ""
    puts "*************************************************"
  else
    exit
  end

end
