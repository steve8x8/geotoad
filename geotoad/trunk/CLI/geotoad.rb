#!/usr/bin/env ruby
# $Id: geotoad.rb,v 1.19 2002/08/05 03:38:51 strombt Exp $

# from ruby-talk 67359 -- make sure your current directory and directory before
# is always in path. The gsub is for Windows machines.
$LOAD_PATH << File.dirname(__FILE__.gsub(/\\/, '/'))
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')


# toss in our own libraries.
require 'interface/display'
require 'interface/progressbar'
require 'geocache/common'
require 'interface/input'
require 'geocache/shadowget'
require 'geocache/searchcode'
require 'geocache/search'
require 'geocache/filter'
require 'geocache/output'
require 'geocache/details'
require 'getoptlong'


class GeoToad
include Common
include Display

# The version gets inserted by makedist.sh
versionID='%VERSION%'
if versionID !~ /^\d/
    $VERSION = '3.5-CURRENT'
else
    $VERSION = versionID.dup
end

$SLEEP=3
$SLOWMODE=350

def initialize
    $TEMP_DIR     = findTempDir
    output        = Output.new
    $validFormats = output.formatList.sort
    @uin          = Input.new
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

    # We need this for the check following
    @queryType         = @option['queryType'] || 'zip'
    @queryArg          = @option['queryArg'] || nil

    # Get this out of the way now.
    if (! @queryArg) || @option['help']
        if (! @queryArg)
            displayError "You forgot to specify a #{@queryType} search argument"
        end
        usage
        exit
    end

    @formatType        = @option['format'] || 'gpx'
    @cacheExpiry       = @option['cacheExpiry'].to_i || 3
    @distanceMax       = @option['distanceMax'] || 10
    @queryTitle        = "GeoToad: #{@queryArg}"
    @defaultOutputFile = "gtout-" + @queryType + "-" + @queryArg

    # This is a global. Not cool.
    $slowLink          = @option['slowlink'] || nil



    if (@option['verbose'])
        enableDebug
    end

    if ! $validFormats.include?(@formatType)
        displayError "#{@formatType} is not a valid supported format."
        usage
        exit
    end
end


def usage
    puts "::: SYNTAX: geotoad.rb [options] <search>"
    puts ""
    puts " -o [filename]          output file name (automatic otherwise)"
    puts " -f [format]            output format type, see list below"
    puts " -q [zip|state|coord]   query type (zip by default)"
    puts " -d/-D [0.0-5.0]        difficulty minimum/maximum"
    puts " -t/-T [0.0-5.0]        terrain minimum/maximum"
    puts " -y    [1-500]          distance maximum in miles (10)"
    puts " -k    [keyword]        title keyword search. Use | to delimit multiple"
    puts " -K    [keyword]        desc keyword search. Use | to delimit multiple"
    puts " -c/-C [username]       include/exclude caches owned by this person"
    puts " -u/-U [username]       include/exclude caches found by this person"
    puts "                            (use : to delimit multiple users!)"
    puts " -p/-P [# days]         include/exclude caches placed in the last X days"
    puts " -r/-R [# days]         include/exclude caches found in the last X days"
    puts " -n                     only include not found caches (virgins)"
    puts " -b                     only include caches with travelbugs"
    puts " -l                     set waypoint id length. (16)"
    puts ""
    puts "::: OUTPUT FORMATS:"
    outputDetails = Output.new
    i=0
    print ""
    $validFormats.each { |type|
        desc = outputDetails.formatDesc(type)
        if (i>5)
            puts ""
            print ""
            i=0
        end
        i=i+1


        if (desc =~ /gpsbabel/)
            type = type + "+"
        elsif (desc =~ /cmconvert/)
            type = type + "="
        end

        printf("  %-10.10s", type);

    }
    puts ""
    puts "    + requires gpsbabel in PATH           = requires cmconvert in PATH"
    puts ""
    puts "::: EXAMPLES:"
    puts "  geotoad.rb 27502"
    puts "  geotoad.rb -d 3 -u helixblue -f vcf -o NC.vcf -q state \'North Carolina\'"
end

## Check the version #######################
def versionCheck
    url = "http://toadstool.se/hacks/geotoad/currentversion.php?type=#{$mode}&version=#{$VERSION}&platform=#{RUBY_PLATFORM}&rubyver=#{RUBY_VERSION}";

    #puts "[^] Checking for latest version of GeoToad..."
    version = ShadowFetch.new(url)
    version.localExpiry=43200
    version.useShadow=0
    version.fetch

    if (($VERSION =~ /^(\d\.\d+\.\d+)$/) && (version.data =~ /^(\d\.\d+\.\d+)/))
        latestVersion = $1;
        if (latestVersion != $VERSION)
            puts ""
            puts "[^] NOTE: Your version of GeoToad is obsolete - #{latestVersion} is now available!";
            puts "[^]       Please download it from http://toadstool.se/hacks/geotoad/"
        end
    end
end

## Make the Initial Query ############################
def downloadGeocacheList
    displayInfo "Your cache directory is " + $TEMP_DIR


    # Mike Capito contributed a patch to allow for multiple
    # queries. He did it as a hash earlier, I'm just simplifying
    # and making it as an array because you probably don't want to
    # mix multiple @queryType's anyways
    @combinedWaypoints = Hash.new

    @queryArg .split(/[:\|]/).each { |queryArg|
        print "\n( o ) Performing #{@queryType} search for #{queryArg} "
        search = SearchCache.new
        if ($slowLink)
            debug "slowlink enabled (useShadow=0)"
            search.useShadow=0
        end

        # only valid for zip or coordinate searches
        if @queryType == "zip" || @queryType == "coord"
            puts "(constraining to #{@distanceMax} miles)"
            @queryTitle = @queryTitle + " (#{@distanceMax}mi. radius)"
            @defaultOutputFile = @defaultOutputFile + "-y" + @distanceMax.to_s
            search.distance(@distanceMax.to_i)
        else
            puts
        end

        if (! search.mode(@queryType, queryArg))
            exit
        end

        search.fetchSearchLoop

        # this gives us support for multiple searches. It adds together the search.waypoints hashes
        # and pops them into the @combinedWaypoints hash.
        @combinedWaypoints.update(search.waypoints)
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

end


def prepareFilter
    # Prepare for the manipulation
    @filtered = Filter.new(@combinedWaypoints)


    # This is where we do a little bit of cheating. In order to avoid downloading the
    # cache details for each cache to see if it's been visited, we do a search for the
    # users on the include or exclude list. We then populate @combinedWaypoints[wid]['visitors']
    # with our discovery.

    userLookups = Array.new
    if (@option['userExclude'])
        @queryTitle = @queryTitle + ", excluding caches done by " + @option['userExclude']
        @defaultOutputFile = @defaultOutputFile + "-U=" + @option['userExclude']
        userLookups = @option['userExclude'].split(':')
    end

    if (@option['userInclude'])
        @queryTitle = @queryTitle + ", excluding caches not done by " + @option['userInclude']
        @defaultOutputFile = @defaultOutputFile + "-u=" + @option['userInclude']
        userLookups = userLookups + @option['userInclude'].split(':')
    end

    userLookups.each { |user|
        search = SearchCache.new
        search.mode('user', user)
        if ($slowLink)
            debug "slowlink enabled (useShadow=0)"
            search.useShadow=0
        end
        search.fetchSearchLoop
        search.waypointList.each { |wid|
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
    beforeFilteredMembersTotal = @filtered.totalWaypoints
    @filtered.removeByElement('membersonly')

    excludedMembersTotal = beforeFilteredMembersTotal - @filtered.totalWaypoints
    if (excludedMembersTotal > 0)
        displayMessage "#{excludedMembersTotal} members-only caches were filtered out (not yet supported)"
    end

    debug "Filter running cycle 1, #{@filtered.totalWaypoints} caches left"

    if @option['difficultyMin']
        @queryTitle = @queryTitle + ", difficulty #{@option['difficultyMin']}+"
        @defaultOutputFile = @defaultOutputFile + "-d" + @option['difficultyMin'].to_s
        @filtered.difficultyMin(@option['difficultyMin'].to_f)
    end
    debug "Filter running cycle 2, #{@filtered.totalWaypoints} caches left"
    if @option['difficultyMax']
        @queryTitle = @queryTitle + ", difficulty #{@option['difficultyMax']} or lower"
        @defaultOutputFile = @defaultOutputFile + "-D" + @option['difficultyMin'].to_s
        @filtered.difficultyMax(@option['difficultyMax'].to_f)
    end
    debug "Filter running cycle 3, #{@filtered.totalWaypoints} caches left"

    if @option['terrainMin']
        @queryTitle = @queryTitle + ", terrain #{@option['terrainMin']}+"
        @defaultOutputFile = @defaultOutputFile + "-t" + @option['terrainMin'].to_s
        @filtered.terrainMin(@option['terrainMin'].to_f)
    end
    debug "Filter running cycle 4, #{@filtered.totalWaypoints} caches left"

    if @option['terrainMax']
        @queryTitle = @queryTitle + ", terrain #{@option['difficultyMax']} or lower"
        @defaultOutputFile = @defaultOutputFile + "-T" + @option['difficultyMin'].to_s
        @filtered.terrainMax(@option['terrainMax'].to_f)
    end

    if @option['foundDateInclude']
        @queryTitle = @queryTitle + ", found in the last  #{@option['foundDateInclude']} days"
        @defaultOutputFile = @defaultOutputFile + "-r=" + @option['foundDateInclude']
        @filtered.foundDateInclude(@option['foundDateInclude'].to_f)
    end

    if @option['foundDateExclude']
        @queryTitle = @queryTitle + ", not found in the last #{@option['foundDateExclude']} days"
        @defaultOutputFile = @defaultOutputFile + "-R=" + @option['foundDateExclude']
        @filtered.foundDateExclude(@option['foundDateExclude'].to_f)
    end

    if @option['placeDateInclude']
        @queryTitle = @queryTitle + ", newer than #{@option['placeDateInclude']} days"
        @defaultOutputFile = @defaultOutputFile + "-p=" + @option['placeDateInclude']
        @filtered.placeDateInclude(@option['placeDateInclude'].to_f)
    end

    if @option['placeDateExclude']
        @queryTitle = @queryTitle + ", over #{@option['placeDateExclude']} days old"
        @defaultOutputFile = @defaultOutputFile + "-P=" + @option['placeDateExclude']
        @filtered.placeDateExclude(@option['placeDateExclude'].to_f)
    end

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




#########################
# Here is where we fetch each geocache page
#
def fetchGeocaches
    # We should really check our local cache and shadowhosts first before
    # doing this. This is just to be nice.
    if (@filtered.totalWaypoints > $SLOWMODE)
        displayMessage "NOTE: Because you may be downloading more than #{$SLOWMODE} waypoints"
        displayMessage "       We will sleep longer between remote downloads to lessen the load"
        displayMessage "       load on the geocaching.com webservers. You may want to constrain"
        displayMessage "       the number of waypoints to download by limiting by difficulty,"
        displayMessage "       terrain, or placement date. Please see README.txt for help."
        $SLEEP=15
    end


    displayMessage "Fetching geocache pages with #{$SLEEP} second rests between remote fetches"
    wpFiltered = @filtered.waypoints
    progress = ProgressBar.new(0, @filtered.totalWaypoints, "Fetching details")

    @detail = CacheDetails.new(wpFiltered)
    token = 0
    wpFiltered.each_key { |wid|
        token = token + 1
        detailURL = @detail.fullURL(wpFiltered[wid]['sid'])
        # This just checks to see where Shadowfetch would grab the information from.
        page = ShadowFetch.new(detailURL)
        src = page.src

        # This actually fetches the page.
        if ($slowLink)
            @detail.useShadow=0
            debug "slowlink enabled (useShadow=0)"
        end

        ret = @detail.fetchWid(wid)
        if (! ret)
            displayWarning "Page for #{wpFiltered[wid]['name']} failed to be parsed, skipping."
            wpFiltered.delete(wid)
            next
        end


        if (page.src)
            if (wpFiltered[wid]['warning'])
                progress.updateText(token, "\"#{wpFiltered[wid]['name']}\" from #{src} (cache is temp. unavailable)")
            else
                progress.updateText(token, "\"#{wpFiltered[wid]['name']}\" from #{src}")
            end
        elsif (src == "remote")
            downloads = downloads + 1
            debug "#{downloads} of #{quitAfterFetch} remote downloads so far"
            displayMessage "  (sleeping for #{$SLEEP} seconds)"
            sleep $SLEEP
        else
            progress.updateText(token, "\"#{wpFiltered[wid]['name']}\" (could not fetch, private cache?)")
            wpFiltered.delete(wid)
        end
    }
end


## step #2 in filtering! ############################
# In this stage, we actually have to download all the information on the caches in order to decide
# whether or not they are keepers.
def postFetchFilter
    @filtered= Filter.new(@detail.waypoints)

    # caches with warnings we choose not to include.
    @filtered.removeByElement('warning')

    if @option['descKeyword']
        @queryTitle = @queryTitle + ", matching desc keywords #{@option['descKeyword']}"
        @defaultOutputFile = @defaultOutputFile + "-K=" + @option['descKeyword']
        @filtered.descKeyword(@option['descKeyword'])
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
    if (@filtered.totalWaypoints < 1)
        displayWarning "No caches to generate output for!"
        exit
    end
end



## save the file #############################################
def saveFile
    puts ""
    output = Output.new
    displayInfo "Output format selected is #{output.formatDesc(@formatType)} format"
    output.input(@filtered.waypoints)
    output.formatType=@formatType
    if (@option['waypointLength'])
        output.waypointLength=@option['waypointLength'].to_i
    end


    # if we have selected the name of the output file, use it.
    # otherwise, take our invented name, sanitize it, and slap a file extension on it.
    if (@option['output'])
        outputFile = @option['output']
    else
        outputFile = @defaultOutputFile.gsub(/\W/, '_')
        outputFile.gsub!(/_+/, '_')
        outputFile = outputFile + "." + output.formatExtension(@formatType)
    end

    # prepend the current working directory. This is mostly done as a service to
    # users who just double click to launch GeoToad, and wonder where their output file went.
    if outputFile !~ /[\/\\]/
        outputFile = Dir.getwd + '/' + outputFile
    end
    
    # Lets not mix and match DOS and UNIX /'s, we'll just make everyone like us!
    outputFile.gsub!(/\\/, '/')

    # append time to our title
    @queryTitle = @queryTitle + " (" + Time.now.strftime("%d%b%y %H:%M") + ")"

    # and do the dirty.
    outputData = output.prepare(@queryTitle);
    output.commit(outputFile)
    displayMessage "Saved to #{outputFile}"
end


def close
    # Not currently used.
end

end


###### MAIN ACTIVITY ###############################################################
puts "GeoToad #{$VERSION} (#{RUBY_PLATFORM}-#{RUBY_VERSION}) - Please report bugs to geotoad@toadstool.se"
cli = GeoToad.new

while(1)
  cli.getoptions
  if (! $slowLink)
      cli.versionCheck
  end

  cli.downloadGeocacheList
  cli.prepareFilter
  cli.preFetchFilter
  cli.fetchGeocaches
  cli.postFetchFilter
  cli.saveFile
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

