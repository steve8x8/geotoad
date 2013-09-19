#!/usr/bin/env ruby
#
# This is the main geotoad binary.
#
$LOAD_PATH << File.dirname(__FILE__.gsub(/\\/, '/'))
$LOAD_PATH << File.dirname(__FILE__.gsub(/\\/, '/')) + '/lib'
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')

if RUBY_VERSION.gsub('.', '').to_i < 190
  puts "ERROR: The version of Ruby your system has installed is #{RUBY_VERSION}, but we now require 1.9.0 or higher"
  sleep(5)
  exit(99)
end
Encoding.default_external = Encoding::UTF_8
if RUBY_VERSION.gsub('.', '').to_i >= 200
  puts "WARNING: GeoToad has not been thoroughly tested with Ruby versions >= 2.0 yet!"
  sleep(5)
end

$delimiters = /[\|:]/
$delimiter = '|'

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
  $ZEROTIME = 315576000

  # conversion miles to kilometres
  $MILE2KM = 1.609344

  def initialize
    $debugMode    = 0
    output        = Output.new
    $validFormats = output.formatList.sort
    @uin          = Input.new
    $CACHE_DIR    = findCacheDir()
    @configDir    = findConfigDir
    $mapping      = loadMapping()
  end

  def getoptions
    if ARGV[0]
      # command line arguments
      @option = @uin.getopt
      $mode = 'CLI'
    else
      # Then go into interactive.
      @option = @uin.interactive
      $mode = 'TUI'
    end

    if (@option['verbose'])
      enableDebug
    else
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

    if ! @option['clearCache'] && ! @queryArg
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
      @distanceMax    /= $MILE2KM
      # round to multiple of ~5ft
      @distanceMax     = sprintf("%.3f", @distanceMax).to_f
    end
    debug "Internally using distance #{@distanceMax} miles."
    # include query type, will be parsed by output.rb
    @queryTitle        = "GeoToad: #{@queryType} = #{@queryArg}"
    @defaultOutputFile = "gt_" + @queryArg.to_s

    @formatTypes.split($delimiters).each { |formatType|
      if ! $validFormats.include?(formatType)
        displayError "#{formatType} is not a valid supported format."
        @uin.usage
        exit
      end
    }

    @limitPages = @option['limitSearchPages'].to_i
    debug "Limiting search to #{@limitPages.inspect} pages" if (@limitPages != 0)

    return @option
  end

  def commandline(optHash)
    cmdline = ""
  # code stolen from interface/input.rb
    hidden_opts = ['queryArg', 'outDir', 'outFile', 'user', 'password', 'usemetric', 'verbose']
    hidden_args = ['userInclude', 'userExclude', 'ownerInclude', 'ownerExclude', 'output']
    # hide unlimited search
    if optHash['limitSearchPages'] == 0
      hidden_opts.push('limitSearchPages')
    end
    optHash.keys.sort.each { |option|
      # "empty" non-nil value = "X" in TUI
      if optHash[option] and ! hidden_opts.include?(option)
        if optHash[option].to_s.empty? or optHash[option] == "X"
          cmdline << " --#{option}"
        elsif not optHash[option].to_s.empty?
          cmdline << " --#{option}="
          if ! hidden_args.include?(option)
            # Omit the quotes if the argument is 'simple'
            if optHash[option].to_s =~ /^[\w\.:]+$/
              cmdline << "#{optHash[option]}"
            else
              cmdline << "\'#{optHash[option]}\'"
            end
          else # hide args
            cmdline << optHash[option].gsub(/[^=%]/, '*').gsub(/\*\**/, '*')
          end
        end
        # in the metric case, we must append "km" to the distance
        if option == 'distanceMax' and optHash['usemetric']
          cmdline << "km"
        end
      end
    }
    # do not append queryArg
    return cmdline
  end

  ## Check the version #######################
  def comparableVersion(text)
    # Make a calculatable/comparable version number
    parts = text.split('.')
    version = (parts[0].to_i * 10000) + (parts[1].to_i * 100) + parts[2].to_i
    #puts version
    return version
  end

  def versionCheck
    if $VERSION =~ /CURRENT/
      return nil
    end

    url = "http://code.google.com/p/geotoad/wiki/CurrentDevelVersion"

    debug "Checking for latest version of GeoToad from #{url}"
    version = ShadowFetch.new(url)
    version.localExpiry = 3 * 86400	# 3 days
    version.maxFailures = 0
    version.fetch

    if (($VERSION =~ /^(\d\.\d+\.\d+)/) && (version.data =~ /version=(\d\.\d+[\.\d]+)/))
      latestVersion = $1
      releaseNotes = $2

      if comparableVersion(latestVersion) > comparableVersion($VERSION)
        puts "------------------------------------------------------------------------"
        puts "* NOTE: GeoToad development version #{latestVersion} is now available!"
        puts "* Download from http://code.google.com/p/geotoad/downloads/list?can=1"
        puts "------------------------------------------------------------------------"
        version.data.scan(/\<div .*? id="wikimaincol"\>\s*(.*?)\s*\<\/div\>/m) do |notes|
          text = notes[0].dup
          text.gsub!(/\<\/?tt\>/i, '')
          #text.gsub!(/\<p\>/i, "\n")
          text.gsub!(/\<h[0-9]\>/i, "\n\+ ")
          text.gsub!(/\<li\>/i, "\n  * ")
          text.gsub!(/\<a[^\>]+href=\"\/p\/geotoad\/wiki\/(.*?)\"\>\1\<\/a\>\s+/i) { "[#{$1}] " }
          text.gsub!(/\<a[^\>]+href=\"\#.*?\>/i, '')
          text.gsub!(/\<.*?\>/, '')
          text.gsub!(/\n\n+/, "\n")
          text.gsub!(/\&nbsp;/, '-')
          text = CGI::unescapeHTML(text)
          #puts text
          textlines = text.split("\n")
          (1..20).each{|line|
            puts textlines[line] if textlines[line]
          }
          puts "  ... see #{url} for more ..." if textlines.length > 20
        end
        puts "------------------------------------------------------------------------"
        displayInfo "(sleeping for 30 seconds)"
        sleep(30)
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
      Find.find(where) { |file|
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
    debug "found #{filecount} files to remove: #{filelist.inspect}"
    if not filelist.empty?
      displayInfo "... #{filecount} files to remove"
      filelist.each { |file|
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

    displayInfo "Clearing account data older than 14 days"
    #system "find #{$CACHE_DIR}/*/account -mtime +14 -type f | xargs -r rm"
    findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/account/", 14)

    displayInfo "Clearing login data older than 14 days"
    #system "find #{$CACHE_DIR}/*/login -mtime +14 -type f | xargs -r rm"
    findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/login/", 14)

    # We do NOT clear cdpf files, in NO case. Instead, preserve old descriptions!
    # If you really want this functionality, uncomment the following displayInfo and findRemoveFiles lines.
    #displayInfo "Clearing cache descriptions older than 31 days"
    ##system "find #{$CACHE_DIR}/*/seek -mtime +31 -writable -name 'cdpf.aspx*' | xargs -r rm"
    #findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/seek/", 31, "^cdpf\\.aspx.*", true)

    displayInfo "Clearing cache details older than 31 days"
    #system "find #{$CACHE_DIR}/*/seek -mtime +31 -writable -name 'cache_details.aspx*' | xargs -r rm"
    findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/seek/", 31, "^cache_details\\.aspx.*", true)

    displayInfo "Clearing lat/lon query data older than 3 days"
    #system "find #{$CACHE_DIR}/*/seek -mtime +3 -writable -name 'nearest.aspx*_lat_*_lng_*' | xargs -r rm"
    findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/seek/", 3, "^nearest\\.aspx.*_lat_.*_lng_.*", true)

    displayInfo "Clearing state and country query data older than 3 days"
    #system "find #{$CACHE_DIR}/*/seek -mtime +3 -writable '(' -name 'nearest.aspx*_state_id_*' -o -name 'nearest.aspx*_country_id_*' ')' | xargs -r rm"
    findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/seek/", 3, "^nearest\\.aspx.*_(country|state)_id_.*", true)

    displayInfo "Clearing other query data older than 14 days"
    #system "find #{$CACHE_DIR}/*/seek -mtime +14 -writable -name 'nearest.aspx*' | xargs -r rm"
    findRemoveFiles("#{$CACHE_DIR}/www.geocaching.com/seek/", 14, "^nearest\\.aspx.*", true)

    displayMessage "Cleared!"
    $CACHE_DIR = findCacheDir()
  end

  ## Make the Initial Query ############################
  def downloadGeocacheList
    displayInfo "Your cache directory is " + $CACHE_DIR

    # Mike Capito contributed a patch to allow for multiple
    # queries. He did it as a hash earlier, I'm just simplifying
    # and making it as an array because you probably don't want to
    # mix multiple @queryType's anyways
    @combinedWaypoints = Hash.new

    displayMessage "Logging in as #{@option['user']}"
    #@cookie = getCookie(@option['user'], @option['password'])
    @cookie = login(@option['user'], @option['password'])
    debug "Login returned cookie #{hideCookie(@cookie).inspect}"
    if (@cookie)
      displayMessage "Login successful"
    else
      displayWarning "Login failed! Check network connection, username and password!"
      displayWarning "Note: Subsequent operations may fail. You've been warned."
    end
    displayMessage "Querying user preferences"
    @dateFormat = getPreferences()
    displayInfo "Using date format #{@dateFormat}"

    if @option['myLogs']
      displayMessage "Retrieving my logs"
      count = getMyLogs()
      displayInfo "Found count: #{count}"
    end

    if @queryType == "zipcode" || @queryType == "coord" || @queryType == 'location'
      @queryTitle = @queryTitle + " (#{@distanceMax}mi. radius)"
      @defaultOutputFile = @defaultOutputFile + "-y" + @distanceMax.to_s
    end

    @queryArg.to_s.split($delimiters).each { |queryArg|
      puts ""
      message = "Performing #{@queryType} search for #{queryArg}"
      search = SearchCache.new

      # only valid for zip or coordinate searches
      if @queryType == "zipcode" || @queryType == "coord" || @queryType == 'location'
        message << " (constraining to #{@distanceMax} miles)"
        search.distance = @distanceMax
      end
      displayMessage message

      # limit search page count
      search.max_pages = @limitPages

      # set tx filter if only one cache type
      if @option['cacheType'] and (@option['cacheType'].split($delimiters).length == 1)
        search.txfilter = @option['cacheType']
      end

      # exclude own found
      search.notyetfound = (@option['notFoundByMe'] ? true : false)

      if (! search.setType(@queryType, queryArg))
        displayWarning "Could not determine search type for #{@queryType} \"#{queryArg}\""
        displayWarning "You may want to remove special characters or try a \"coord\" search instead"
        #displayError "No valid search type. Exiting."
        #exit
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
    @combinedWaypoints.each_key { |wp|
      debug "pre-filter: #{wp}"
      waypointsExtracted = waypointsExtracted + 1
    }

    debug "waypoints extracted: #{waypointsExtracted}, combined: #{@combinedWaypoints.length}"
    if (waypointsExtracted < @combinedWaypoints.length)
      displayWarning "Downloaded #{@combinedWaypoints.length} waypoints, but only #{waypointsExtracted} parsed!"
    end
    return waypointsExtracted
  end


  def prepareFilter
    # Prepare for the manipulation
    @filtered = Filter.new(@combinedWaypoints)

    if @option['notFoundByMe']
      @queryTitle = @queryTitle + ", not found by " + @option['user']
    end

    # This is where we do a little bit of cheating. In order to avoid downloading the
    # cache details for each cache to see if it's been visited, we do a search for the
    # users on the include or exclude list. We then populate @combinedWaypoints[wid]['visitors']
    # with our discovery.

    userLookups = Array.new
    if @option['userExclude'] and not @option['userExclude'].empty?
      @queryTitle = @queryTitle + ", excluding caches done by " + @option['userExclude']
      @defaultOutputFile = @defaultOutputFile + "-E=" + @option['userExclude']
      userLookups = @option['userExclude'].split($delimiters)
    end

    if @option['userInclude'] and not @option['userInclude'].empty?
      @queryTitle = @queryTitle + ", excluding caches not done by " + @option['userInclude']
      @defaultOutputFile = @defaultOutputFile + "-e=" + @option['userInclude']
      userLookups = userLookups + @option['userInclude'].split($delimiters)
    end

    userLookups.each { |user|
      # issue 236: if "user" is file, read that
      if (user =~ /(.*)=(.*)/)
        username = $1
        filename = $2
        puts ""
        displayMessage "Read #{filename} for #{username}"
        counter = 0
        # read file (1st column)
        begin
          File.foreach(filename) { |line|
          if (line =~ /^(GC\w+)/i)
            wid = $1
            debug "Add #{wid} for #{username}"
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
        waypoints.keys.each { |wid|
          @filtered.addVisitor(wid, user)
        }
      end
    }
  end


  ## step #1 in filtering! ############################
  # This step filters out all the geocaches by information
  # found from the searches.
  def preFetchFilter
    puts ""
    @filtered = Filter.new(@combinedWaypoints)
    debug "Filter running cycle 1, #{@filtered.totalWaypoints} caches left"

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['cacheType']
      @queryTitle = @queryTitle + ", type #{@option['cacheType']}"
      @defaultOutputFile = @defaultOutputFile + "-c" + @option['cacheType']
      @filtered.cacheType(@option['cacheType'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Cache type filtering removed #{excludedFilterTotal} caches."
    end

    if $DTSFILTER
    #-------------------
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['difficultyMin']
      @queryTitle = @queryTitle + ", difficulty #{@option['difficultyMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-d" + @option['difficultyMin'].to_s
      @filtered.difficultyMin(@option['difficultyMin'].to_f)
    end
    if @option['difficultyMax']
      @queryTitle = @queryTitle + ", difficulty #{@option['difficultyMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + "-D" + @option['difficultyMax'].to_s
      @filtered.difficultyMax(@option['difficultyMax'].to_f)
    end
    if @option['terrainMin']
      @queryTitle = @queryTitle + ", terrain #{@option['terrainMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-t" + @option['terrainMin'].to_s
      @filtered.terrainMin(@option['terrainMin'].to_f)
    end
    if @option['terrainMax']
      @queryTitle = @queryTitle + ", terrain #{@option['terrainMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + "-T" + @option['terrainMax'].to_s
      @filtered.terrainMax(@option['terrainMax'].to_f)
    end
    if @option['sizeMin']
      @queryTitle = @queryTitle + ", size #{@option['sizeMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-s" + @option['sizeMin'].to_s
      @filtered.sizeMin(@option['sizeMin'])
    end
    if @option['sizeMax']
      @queryTitle = @queryTitle + ", size #{@option['sizeMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + "-S" + @option['sizeMax'].to_s
      @filtered.sizeMax(@option['sizeMax'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Diff/Terr/Size filtering removed #{excludedFilterTotal} caches."
    end
    #-------------------
    end # $DTSFILTER

    debug "Filter running cycle 2, #{@filtered.totalWaypoints} caches left"

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['foundDateInclude']
      @queryTitle = @queryTitle + ", found in the last  #{@option['foundDateInclude']} days"
      @defaultOutputFile = @defaultOutputFile + "-r=" + @option['foundDateInclude'].to_s
      @filtered.foundDateInclude(@option['foundDateInclude'].to_f)
    end
    if @option['foundDateExclude']
      @queryTitle = @queryTitle + ", not found in the last #{@option['foundDateExclude']} days"
      @defaultOutputFile = @defaultOutputFile + "-R=" + @option['foundDateExclude'].to_s
      @filtered.foundDateExclude(@option['foundDateExclude'].to_f)
    end
    if @option['placeDateInclude']
      @queryTitle = @queryTitle + ", newer than #{@option['placeDateInclude']} days"
      @defaultOutputFile = @defaultOutputFile + "-j=" + @option['placeDateInclude'].to_s
      @filtered.placeDateInclude(@option['placeDateInclude'].to_f)
    end
    if @option['placeDateExclude']
      @queryTitle = @queryTitle + ", over #{@option['placeDateExclude']} days old"
      @defaultOutputFile = @defaultOutputFile + "-J=" + @option['placeDateExclude'].to_s
      @filtered.placeDateExclude(@option['placeDateExclude'].to_f)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Date filtering removed #{excludedFilterTotal} caches."
    end

    debug "Filter running cycle 3, #{@filtered.totalWaypoints} caches left"

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['notFound']
      @queryTitle = @queryTitle + ", virgins only"
      @defaultOutputFile = @defaultOutputFile + "-n"
      @filtered.notFound
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Unfound filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['travelBug']
      @queryTitle = @queryTitle + ", only with TB's"
      @defaultOutputFile = @defaultOutputFile + "-b"
      @filtered.travelBug
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Trackable filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['ownerExclude'])
      @queryTitle = @queryTitle + ", excluding caches by #{@option['ownerExclude']}"
      @option['ownerExclude'].split($delimiters).each { |owner|
        @filtered.ownerExclude(owner)
      }
    end
    if (@option['ownerInclude'])
      @queryTitle = @queryTitle + ", excluding caches not by #{@option['ownerInclude']}"
      @option['ownerInclude'].split($delimiters).each { |owner|
        @filtered.ownerInclude(owner)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Owner filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['userExclude'])
      @option['userExclude'].split($delimiters).each { |user|
        @filtered.userExclude(user)
      }
    end
    if (@option['userInclude'])
      @option['userInclude'].split($delimiters).each { |user|
        @filtered.userInclude(user)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "User filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['titleKeyword']
      @queryTitle = @queryTitle + ", matching title keywords #{@option['titleKeyword']}"
      @defaultOutputFile = @defaultOutputFile + "-k=" + @option['titleKeyword']
      @filtered.titleKeyword(@option['titleKeyword'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Title keyword filtering removed #{excludedFilterTotal} caches."
    end

    displayMessage "Filter stage 1 complete, #{@filtered.totalWaypoints} caches left"
  end


  def copyGeocaches
    # don't load details, just copy from search results
    wpFiltered = @filtered.waypoints
    @detail = CacheDetails.new(wpFiltered)
  end

  def fetchGeocaches
    puts ""
    displayMessage "Fetching geocache pages"
    wpFiltered = @filtered.waypoints
    progress = ProgressBar.new(0, @filtered.totalWaypoints, "Read")
    @detail = CacheDetails.new(wpFiltered)
    @detail.preserve = @preserveCache
    token = 0

    wpFiltered.each_key { |wid|
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
          message = "(could not fetch, private cache?)"
        else
          # don't throw this out yet, will get null entries in output though
          #message = "(error)"
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
      progress.updateText(token, "[#{wid}]".ljust(9)+" \"#{wpFiltered[wid]['name']}\" from #{page.src} #{message}")

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
    if ! @option['includeDisabled']
      @filtered.removeByElement('disabled')
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Disabled filtering removed #{excludedFilterTotal} caches."
    end

    # exclude Premium Member Only caches on request
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['noPMO']
      @filtered.removeByElement('membersonly')
    end
    if @option['onlyPMO']
      @filtered.removeByElement('membersonly', false)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "PMO filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['descKeyword']
      @queryTitle = @queryTitle + ", matching desc keywords #{@option['descKeyword']}"
      @defaultOutputFile = @defaultOutputFile + "-K=" + @option['descKeyword']
      @filtered.descKeyword(@option['descKeyword'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Keyword filtering removed #{excludedFilterTotal} caches."
    end

    if not $DTSFILTER
    #-------------------
    beforeFilterTotal = @filtered.totalWaypoints
    if @option['difficultyMin']
      @queryTitle = @queryTitle + ", difficulty #{@option['difficultyMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-d" + @option['difficultyMin'].to_s
      @filtered.difficultyMin(@option['difficultyMin'].to_f)
    end
    if @option['difficultyMax']
      @queryTitle = @queryTitle + ", difficulty #{@option['difficultyMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + "-D" + @option['difficultyMax'].to_s
      @filtered.difficultyMax(@option['difficultyMax'].to_f)
    end
    if @option['terrainMin']
      @queryTitle = @queryTitle + ", terrain #{@option['terrainMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-t" + @option['terrainMin'].to_s
      @filtered.terrainMin(@option['terrainMin'].to_f)
    end
    if @option['terrainMax']
      @queryTitle = @queryTitle + ", terrain #{@option['terrainMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + "-T" + @option['terrainMax'].to_s
      @filtered.terrainMax(@option['terrainMax'].to_f)
    end
    if @option['sizeMin']
      @queryTitle = @queryTitle + ", size #{@option['sizeMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-s" + @option['sizeMin'].to_s
      @filtered.sizeMin(@option['sizeMin'])
    end
    if @option['sizeMax']
      @queryTitle = @queryTitle + ", size #{@option['sizeMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + "-S" + @option['sizeMax'].to_s
      @filtered.sizeMax(@option['sizeMax'])
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Diff/Terr/Size filtering removed #{excludedFilterTotal} caches."
    end
    #-------------------
    end # not $DTSFILTER

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['funFactorMin']
      @queryTitle = @queryTitle + ", funFactor #{@option['funFactorMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-f" + @option['funFactorMin'].to_s
      @filtered.funFactorMin(@option['funFactorMin'].to_f)
    end
    if @option['funFactorMax']
      @queryTitle = @queryTitle + ", funFactor #{@option['funFactorMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + '-F' + @option['funFactorMax'].to_s
      @filtered.funFactorMax(@option['funFactorMax'].to_f)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "FunFactor filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if @option['favFactorMin']
      @queryTitle = @queryTitle + ", favFactor #{@option['favFactorMin']}+"
      @defaultOutputFile = @defaultOutputFile + "-f" + @option['favFactorMin'].to_s
      @filtered.favFactorMin(@option['favFactorMin'].to_f)
    end
    if @option['favFactorMax']
      @queryTitle = @queryTitle + ", favFactor #{@option['favFactorMax']} or lower"
      @defaultOutputFile = @defaultOutputFile + '-F' + @option['favFactorMax'].to_s
      @filtered.favFactorMax(@option['favFactorMax'].to_f)
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "FavFactor filtering removed #{excludedFilterTotal} caches."
    end

    # We filter for users again. While this may be a bit obsessive, this is in case
    # our local cache is not valid.
    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['userExclude'])
      @option['userExclude'].split($delimiters).each { |user|
        @filtered.userExclude(user)
      }
    end
    if (@option['userInclude'])
      @option['userInclude'].split($delimiters).each { |user|
        @filtered.userInclude(user)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "User filtering removed #{excludedFilterTotal} caches."
    end

    beforeFilterTotal = @filtered.totalWaypoints
    if (@option['attributeExclude'])
      @option['attributeExclude'].split($delimiters).each { |attribute|
        @filtered.attributeExclude(attribute)
      }
    end
    if (@option['attributeInclude'])
      @option['attributeInclude'].split($delimiters).each { |attribute|
        @filtered.attributeInclude(attribute)
      }
    end
    excludedFilterTotal = beforeFilterTotal - @filtered.totalWaypoints
    if (excludedFilterTotal > 0)
      displayMessage "Attribute filtering removed #{excludedFilterTotal} caches."
    end

    displayMessage "Filter stage 2 complete, #{@filtered.totalWaypoints} caches left"
    return @filtered.totalWaypoints
  end



  ## save the file #############################################
  def saveFile
    puts ""
    formatTypeCounter = 0
    # if we have selected the name of the output file, use it for first run
    #   for subsequent runs, drop extension and append default (for type) one
    # otherwise, take our invented name, sanitize it, and slap a file extension on it.
    outputFileBase = nil
    if @option['output']
      filename = @option['output'].dup
      #displayInfo "Output filename: #{filename}"
      filename.gsub!('\\', '/')
      if filename and filename !~ /\/$/
        outputFileBase = File.basename(filename)
      end
    end
    # automatic, or bad input
    if not outputFileBase
      # flag as automatic for suffixing
      @option['output'] = nil
      outputFileBase = @defaultOutputFile.gsub(/[^0-9A-Za-z\.-]/, '_')
      outputFileBase.gsub!(/_+/, '_')
      # shorten at a somewhat randomly chosen place to fit in filesystem
      if outputFileBase.length > 220
        outputFileBase = outputFileBase[0..215] + "_etc"
      end
    end
    if (! @option['output']) || (@option['output'] !~ /\//)
      # prepend the current working directory. This is mostly done as a service to
      # users who just double click to launch GeoToad, and wonder where their output file went.
      outputDir = @option['outDir']
      if not outputDir
        outputDir = Dir.pwd
      end
    else
      # fool it so that trailing slashes work.
      outputDir = File.dirname(@option['output'] + "x")
    end
    debug "Using output #{outputDir}/#{outputFileBase}"
    # loop over all chosen formats
    @formatTypes.split($delimiters).each { |formatType|
      output = Output.new
      displayInfo "Output format: #{output.formatDesc(formatType)} format"
      output.input(@filtered.waypoints)
      output.formatType = formatType
      if (@option['waypointLength'])
        output.waypointLength=@option['waypointLength'].to_i
      end
      # keep filename if first run and not automatic
      # strip suffix only on subsqeuent runs
      if (formatTypeCounter > 0)
        outputFileBase.gsub!(/\.[^\.]*$/, '')
      end
      # append suffix if automatic or subsequent runs
      if (not @option['output']) || (formatTypeCounter > 0)
        outputFileBase = outputFileBase + "." + output.formatExtension(formatType)
      end
      outputFile = outputDir + '/' + outputFileBase
      # Lets not mix and match DOS and UNIX /'s, we'll just make everyone like us!
      outputFile.gsub!(/\\/, '/')
      displayInfo "Output filename: #{outputFile}"

      # append time to our title
      queryTitle = @queryTitle + " (" + Time.now.strftime("%d%b%y %H:%M") + ")"

      # and do the dirty.
      outputData = output.prepare(queryTitle, @option['user'])
      output.commit(outputFile)
      displayMessage "Saved to #{outputFile}"
      puts ""

      formatTypeCounter += 1
    } # end format loop
  end


  def close
    # Not currently used.
  end

end

# for Ocra build
exit if Object.const_defined?(:Ocra)

###### MAIN ACTIVITY ###############################################################
# have some output before initializing the GeoToad, Output, Template classes
include Messages
displayTitleMessage "GeoToad #{$VERSION} (#{RUBY_PLATFORM}-#{RUBY_VERSION})"
displayInfo "Report bugs or suggestions at http://code.google.com/p/geotoad/issues/"
displayInfo "Please include verbose output (-v) without passwords in the bug report."
cli = GeoToad.new
cli.versionCheck
puts

while true
  options = cli.getoptions
  if ! options['noHistory']
    cmdline = cli.commandline(options)
    # sort array representation of all options but queryArg, hash to hex
    # this should make entries unique even across multiple users
    cmdhash = Zlib.crc32(options.dup.merge({'queryArg'=>nil}).to_a.sort.to_s).to_s(16)
    cli.debug "History #{cmdhash}: #{cmdline}"
    history = cli.loadHistory()
    cli.mergeHistory(history, cmdline, cmdhash)
    cli.saveHistory(history)
  end
  if options['clearCache']
    cli.clearCacheDirectory()
  end

  # avoid login if clearing only
  count = 0
  if options['queryArg']
    count = cli.downloadGeocacheList()
  end
  if count < 1
    cli.displayWarning "No caches found in search, exiting early."
  else
    cli.displayMessage "#{count} caches matching query argument(s)."
    cli.prepareFilter
    #if (options['queryType'] != 'wid') and (options['queryType'] != 'guid')
    cli.preFetchFilter
    #end

    if options['noCacheDescriptions']
      cli.displayMessage "Skipping retrieval of cache descriptions"
      cli.copyGeocaches
    else
      cli.fetchGeocaches
    end
    caches = cli.postFetchFilter
    if caches > 0
      cli.saveFile
    else
      cli.displayMessage "No caches were found that matched your requirements."
    end
  end
  # dummy operation
  cli.close


  # Don't loop if you're in automatic mode.
  if ($mode == "TUI")
    puts ""
    puts "***********************************************"
    puts "* Complete! Press Enter to return to the menu *"
    puts "***********************************************"
    $stdin.gets
  else
    exit
  end
end
