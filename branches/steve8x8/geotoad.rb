#!/usr/bin/env ruby
#
# This is the main geotoad binary.
#
$LOAD_PATH << File.dirname(__FILE__.gsub(/\\/, '/'))
$LOAD_PATH << File.dirname(__FILE__.gsub(/\\/, '/')) + '/lib'
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')

$isRuby19 = false

if RUBY_VERSION.gsub('.', '').to_i < 180
  puts "ERROR: The version of Ruby your system has installed is #{RUBY_VERSION}, but we now require 1.8.0 or higher"
  sleep(5)
  exit(99)
end
if RUBY_VERSION.gsub('.', '').to_i >= 190
  $isRuby19 = true
end

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

class GeoToad
  include Common
  include Messages
  include Auth
  $VERSION = GTVersion.version
  $SLEEP = 1.5
  $SLOWMODE = 350

  # *if* cache D/T/S extraction works, early filtering is possible
  #$DTSFILTER = false
  $DTSFILTER = true

  def initialize
    $debugMode    = 0
    output        = Output.new
    $validFormats = output.formatList.sort
    @uin          = Input.new
    $CACHE_DIR    = findCacheDir()
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
        displayError "You must specify a username and password to download coordinates from Geocaching.com"
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
      @distanceMax    /= 1.609344
      # round to multiple of ~5ft
      @distanceMax     = sprintf("%.3f", @distanceMax).to_f
    end
    debug "Internally using distance #{@distanceMax} miles."
    # include query type, will be parsed by output.rb
    @queryTitle        = "GeoToad: #{@queryType} = #{@queryArg}"
    @defaultOutputFile = "gt_" + @queryArg.to_s

   @formatTypes.split(/[:\|]/).each { |formatType|
    if ! $validFormats.include?(formatType)
      displayError "#{formatType} is not a valid supported format."
      @uin.usage
      exit
    end
   }

    @limitPages = @option['limitSearchPages'].to_i
    debug "Limiting search to #{@limitPages.inspect} pages"

    return @option
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

    url = "http://code.google.com/p/geotoad/wiki/CurrentDevelVersion";

    debug "Checking for latest version of GeoToad from #{url}"
    version = ShadowFetch.new(url)
    version.localExpiry = 3 * 86400	# 3 days
    version.maxFailures = 0
    version.fetch

    if (($VERSION =~ /^(\d\.\d+\.\d+)$/) && (version.data =~ /version=(\d\.\d+[\.\d]+)/))
      latestVersion = $1
      releaseNotes = $2;

      if comparableVersion(latestVersion) > comparableVersion($VERSION)
        puts "------------------------------------------------------------------------"
        puts "* NOTE: GeoToad development version #{latestVersion} is now available!"
        puts "* Download from http://code.google.com/p/geotoad/downloads/list?can=1"
        puts "------------------------------------------------------------------------"
        version.data.scan(/\<div .*? id="wikimaincol"\>\s*(.*?)\s*\<\/div\>/m) do |notes|
          text = CGI::unescapeHTML(notes[0])
          text.gsub!(/\<\/?tt\>/i, '')
          #text.gsub!(/\<p\>/i, "\n")
          text.gsub!(/\<h[0-9]\>/i, "\n")
          text.gsub!(/\<li\>/i, "\n * ")
          text.gsub!(/\<a href=\"\#.*?\>/i, '')
          text.gsub!(/\<a href=\"\/p\/.*\/(.*?)\"\>/i) { "[#{$1}] " }
          text.gsub!(/\<.*?\>/, '')
          text.gsub!(/\n\n*/, "\n")
          puts text
        end
        puts "------------------------------------------------------------------------"
        puts "(sleeping for 5 seconds)"
        sleep(5)
      end
    end
    debug "Check complete."
  end

  def clearCacheDirectory
    puts "* Clearing #{$CACHE_DIR}"
    FileUtils::remove_dir($CACHE_DIR)
    puts "* Cleared!"
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
    displayMessage "Using date format #{@dateFormat}"

    if @queryType == "zipcode" || @queryType == "coord" || @queryType == 'location'
      @queryTitle = @queryTitle + " (#{@distanceMax}mi. radius)"
      @defaultOutputFile = @defaultOutputFile + "-y" + @distanceMax.to_s
    end

    @queryArg.to_s.split(/[:\|]/).each { |queryArg|
      print "\n( o ) Performing #{@queryType} search for #{queryArg} "
      search = SearchCache.new

      # only valid for zip or coordinate searches
      if @queryType == "zipcode" || @queryType == "coord" || @queryType == 'location'
        puts "(constraining to #{@distanceMax} miles)"
        search.distance = @distanceMax
      else
        puts
      end

      # limit search page count
      search.max_pages = @limitPages

      if (! search.setType(@queryType, queryArg))
        displayError "(could not determine search type for #{@queryType}, exiting)"
        exit
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

    if (waypointsExtracted < (@combinedWaypoints.length - 2))
      displayWarning "downloaded #{@combinedWaypoints.length} waypoints, but I can only parse #{waypointsExtracted} of them!"
    end
    return waypointsExtracted
  end


  def prepareFilter
    # Prepare for the manipulation
    @filtered = Filter.new(@combinedWaypoints)

    # This is where we do a little bit of cheating. In order to avoid downloading the
    # cache details for each cache to see if it's been visited, we do a search for the
    # users on the include or exclude list. We then populate @combinedWaypoints[wid]['visitors']
    # with our discovery.

    userLookups = Array.new
    if @option['userExclude'] and not @option['userExclude'].empty?
      @queryTitle = @queryTitle + ", excluding caches done by " + @option['userExclude']
      @defaultOutputFile = @defaultOutputFile + "-E=" + @option['userExclude']
      userLookups = @option['userExclude'].split(':')
    end

    if @option['userInclude'] and not @option['userInclude'].empty?
      @queryTitle = @queryTitle + ", excluding caches not done by " + @option['userInclude']
      @defaultOutputFile = @defaultOutputFile + "-e=" + @option['userInclude']
      userLookups = userLookups + @option['userInclude'].split(':')
    end

    userLookups.each { |user|
      search = SearchCache.new
      search.setType('user', user)
      waypoints = search.getResults()
      waypoints.keys.each { |wid|
        @filtered.addVisitor(wid, user)
      }
    }
  end


  ## step #1 in filtering! ############################
  # This step filters out all the geocaches by information
  # found from the searches.
  def preFetchFilter
    puts ""
    @filtered = Filter.new(@combinedWaypoints)
    debug "Filter running cycle 1, #{@filtered.totalWaypoints} caches left"
    if @option['cacheType']
      @queryTitle = @queryTitle + ", type #{@option['cacheType']}"
      @defaultOutputFile = @defaultOutputFile + "-c" + @option['cacheType']
      @filtered.cacheType(@option['cacheType'])
    end

    if $DTSFILTER
    #-------------------
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
    #-------------------
    end # not $DTSFILTER
    debug "Filter running cycle 2, #{@filtered.totalWaypoints} caches left"

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
    debug "Filter running cycle 3, #{@filtered.totalWaypoints} caches left"

    if @option['notFound']
      @queryTitle = @queryTitle + ", virgins only"
      @defaultOutputFile = @defaultOutputFile + "-n"
      @filtered.notFound
    end

    if @option['travelBug']
      @queryTitle = @queryTitle + ", only with TB's"
      @defaultOutputFile = @defaultOutputFile + "-b"
      @filtered.travelBug
    end


    beforeOwnersTotal = @filtered.totalWaypoints
    if (@option['ownerExclude'])
      @queryTitle = @queryTitle + ", excluding caches by #{@option['ownerExclude']}"
      @option['ownerExclude'].split(/[:\|]/).each { |owner|
        @filtered.ownerExclude(owner)
      }
    end

    if (@option['ownerInclude'])
      @queryTitle = @queryTitle + ", excluding caches not by #{@option['ownerInclude']}"
      @option['ownerInclude'].split(/[:\|]/).each { |owner|
        @filtered.ownerInclude(owner)
      }
    end

    excludedOwnersTotal = beforeOwnersTotal - @filtered.totalWaypoints
    if (excludedOwnersTotal > 0)
      displayMessage "Owner filtering removed #{excludedOwnersTotal} caches from your listing."
    end

    beforeUsersTotal = @filtered.totalWaypoints
    if (@option['userExclude'])
      @option['userExclude'].split(/[:\|]/).each { |user|
        @filtered.userExclude(user)
      }
    end

    if (@option['userInclude'])
      @option['userInclude'].split(/[:\|]/).each { |user|
        @filtered.userInclude(user)
      }
    end

    if @option['titleKeyword']
      @queryTitle = @queryTitle + ", matching title keywords #{@option['titleKeyword']}"
      @defaultOutputFile = @defaultOutputFile + "-k=" + @option['titleKeyword']
      @filtered.titleKeyword(@option['titleKeyword'])
    end

    excludedUsersTotal = beforeUsersTotal - @filtered.totalWaypoints
    if (excludedUsersTotal > 0)
      displayMessage "User filtering removed #{excludedUsersTotal} caches from your listing."
    end


    displayMessage "First stage filtering complete, #{@filtered.totalWaypoints} caches left"
  end




  def fetchGeocaches
    # We should really check our local cache and shadowhosts first before
    # doing this. This is just to be nice.
    if (@filtered.totalWaypoints > $SLOWMODE)
      displayMessage "NOTE: Because you may be downloading more than #{$SLOWMODE} waypoints"
      displayMessage "       We will sleep longer between remote downloads to lessen the load"
      displayMessage "       on the geocaching.com webservers. You may want to constrain"
      displayMessage "       the number of waypoints to download by limiting by difficulty,"
      displayMessage "       terrain, or placement date. Please see README.txt for help."
      $SLEEP = $SLEEP * 2
    end

    displayMessage "Fetching geocache pages with #{$SLEEP} second rests between remote fetches"
    wpFiltered = @filtered.waypoints
    progress = ProgressBar.new(0, @filtered.totalWaypoints, "Reading")
    @detail = CacheDetails.new(wpFiltered)
    @detail.preserve = @preserveCache
    token = 0
    downloads = 0

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
        displayMessage "#{wid} is either unpublished or hidden subscriber-only, skipping."
        next
      elsif ! status or status == 'login-required'
        if (wpFiltered[wid]['warning'])
          debug "Could not parse page, but it had a warning, so I am not invalidating"
          message = "(could not fetch, private cache?)"
        else
          message = "(error)"
        end
      else
        if (wpFiltered[wid]['warning'])
          message = "(unavailable)"
        end
      end
      progress.updateText(token, "[#{wid}] \"#{wpFiltered[wid]['name']}\" from #{page.src} #{message}")

      if status == 'subscriber-only'
        wpFiltered.delete(wid)
      else
        if (page.src == "remote")
          downloads = downloads + 1
          sleep $SLEEP
        end
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
    @filtered= Filter.new(@detail.waypoints)

    # caches with warnings we choose not to include.
    if ! @option['includeDisabled']
      displayMessage "Filtering out disabled caches"
      @filtered.removeByElement('disabled')
    end

    if @option['descKeyword']
      @queryTitle = @queryTitle + ", matching desc keywords #{@option['descKeyword']}"
      @defaultOutputFile = @defaultOutputFile + "-K=" + @option['descKeyword']
      @filtered.descKeyword(@option['descKeyword'])
    end

    if not $DTSFILTER
    #-------------------
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
    #-------------------
    end # not $DTSFILTER

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

    # We filter for users again. While this may be a bit obsessive, this is in case
    # our local cache is not valid.
    beforeUsersTotal = @filtered.totalWaypoints
    if (@option['userExclude'])
      @option['userExclude'].split(/[:\|]/).each { |user|
        @filtered.userExclude(user)
      }
    end

    if (@option['userInclude'])
      @option['userInclude'].split(/[:\|]/).each { |user|
        @filtered.userInclude(user)
      }
    end

    excludedUsersTotal = beforeUsersTotal - @filtered.totalWaypoints
    if (excludedUsersTotal > 0)
      displayMessage "User filtering removed #{excludedUsersTotal} caches from your listing."
    end


    displayMessage "Filter complete, #{@filtered.totalWaypoints} caches left"
    return @filtered.totalWaypoints
  end



  ## save the file #############################################
  def saveFile
    puts ""
    formatTypeCounter = 0
   # loop over all chosen formats
   @formatTypes.split(/[:\|]/).each { |formatType|
    output = Output.new
    displayInfo "Output format selected is #{output.formatDesc(formatType)} format"
    output.input(@filtered.waypoints)
    output.formatType = formatType
    if (@option['waypointLength'])
      output.waypointLength=@option['waypointLength'].to_i
    end

    # if we have selected the name of the output file, use it for first run
    # for subsequent runs, drop the extension and append default one
    # otherwise, take our invented name, sanitize it, and slap a file extension on it.
    outputFile = nil
    if @option['output']
      filename = @option['output'].dup
      #displayInfo "Output filename: #{filename}"
      filename.gsub!('\\', '/')
      if filename and filename !~ /\/$/
        outputFile = File.basename(filename)
      end
      if (formatTypeCounter > 0)
        # replace/add extension
        outputFile.gsub!(/\.[^\.]*$/, '')
        outputFile = outputFile + "." + output.formatExtension(formatType)
      end
    end

    if not outputFile
      outputFile = @defaultOutputFile.gsub(/[^0-9A-Za-z\.-]/, '_')
      outputFile.gsub!(/_+/, '_')
      if outputFile.length > 220
        outputFile = outputFile[0..215] + "_etc"
      end

      outputFile = outputFile + "." + output.formatExtension(formatType)
    end
    debug "Base output path: #{outputFile}"

    # prepend the current working directory. This is mostly done as a service to
    # users who just double click to launch GeoToad, and wonder where their output file went.

    if (! @option['output']) || (@option['output'] !~ /\//)
      outputDir = Dir.pwd
    else
      # fool it so that trailing slashes work.
      outputDir = File.dirname(@option['output'] + "x")
    end

    outputFile = outputDir + '/' + outputFile


    # Lets not mix and match DOS and UNIX /'s, we'll just make everyone like us!
    outputFile.gsub!(/\\/, '/')
    displayInfo "Output filename: #{outputFile}"

    # append time to our title
    queryTitle = @queryTitle + " (" + Time.now.strftime("%d%b%y %H:%M") + ")"

    # and do the dirty.
    outputData = output.prepare(queryTitle, @option['user']);
    output.commit(outputFile)
    displayMessage "Saved to #{outputFile}"

    formatTypeCounter += 1
   }
   # end format loop
  end


  def close
    # Not currently used.
  end

end

# for Ocra build
exit if Object.const_defined?(:Ocra)

###### MAIN ACTIVITY ###############################################################
puts "GeoToad #{$VERSION} (#{RUBY_PLATFORM}-#{RUBY_VERSION})"
puts "- Report bugs or suggestions at http://code.google.com/p/geotoad/issues/"
puts "- Please include verbose output (-v) without passwords in the bug report."
cli = GeoToad.new
cli.versionCheck

while(1)
  options = cli.getoptions
  if options['clearCache']
    cli.clearCacheDirectory()
  end

  count = cli.downloadGeocacheList()
  if count < 1
    cli.displayWarning "No caches found in search, exiting early."
  else
    cli.displayMessage "#{count} geocaches found in defined area."
    cli.prepareFilter
    if options['queryType'] != 'wid'
      cli.preFetchFilter
    end

    cli.fetchGeocaches
    caches = cli.postFetchFilter
    if caches > 0
      cli.saveFile
    else
      cli.displayMessage "No caches were found that matched your requirements"
    end
    cli.close
  end


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
