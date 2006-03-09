#!/usr/bin/env ruby
# $Id$

$LOAD_PATH << File.dirname(__FILE__.gsub(/\\/, '/'))
$LOAD_PATH << (File.dirname(__FILE__.gsub(/\\/, '/')) + '/' + '..')

# toss in our own libraries.
require 'interface/display'
require 'interface/progressbar'
require 'lib/common'
require 'interface/input'
require 'lib/shadowget'
require 'lib/searchcode'
require 'lib/search'
require 'lib/filter'
require 'lib/output'
require 'lib/details'
require 'lib/auth'
require 'getoptlong'


class GeoToad
include Common
include Display
include Auth

# The version gets inserted by makedist.sh
versionID='%VERSION%'
if versionID !~ /^\d/
    $VERSION = '3.8-CURRENT'
else
    $VERSION = versionID.dup
end

$SLEEP=3
$SLOWMODE=150

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
    @queryType         = @option['queryType'] || 'zipcode'
    @queryArg          = @option['queryArg'] || nil

    # Get this out of the way now.
    if (! @queryArg) || @option['help'] || (! @option['user']) ||  (! @option['password'])
        if (! @queryArg)
            displayError "You forgot to specify a #{@queryType} search argument"
        end
        if (! @option['user']) ||  (! @option['password'])
            displayError "You must specify a username and password to download coordinates from Geocaching.com"
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
    puts " -u <username>          Geocaching.com username, required for coordinates"
    puts " -p <password>          Geocaching.com password, required for coordinates"

    puts " -o [filename]          output file name (automatic otherwise)"
    puts " -f [format]            output format type, see list below"
    puts " -q [zip|state|coord]   query type (zip by default)"
    puts " -d/-D [0.0-5.0]        difficulty minimum/maximum"
    puts " -t/-T [0.0-5.0]        terrain minimum/maximum"
    puts " -y    [1-500]          distance maximum in miles (10)"
    puts " -k    [keyword]        title keyword search. Use | to delimit multiple"
    puts " -K    [keyword]        desc keyword search. Use | to delimit multiple"
    puts " -i/-I [username]       include/exclude caches owned by this person"
    puts " -s/-S [username]       include/exclude caches found by this person"
    puts "                            (use : to delimit multiple users!)"
    puts " -j/-J [# days]         include/exclude caches placed in the last X days"
    puts " -r/-R [# days]         include/exclude caches found in the last X days"
    puts " -n                     only include not found caches (virgins)"
    puts " -b                     only include caches with travelbugs"
    puts " -e                     enable EasyName waypoint id's"
    puts " -l                     set EasyName waypoint id length. (16)"
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


        if (outputDetails.formatRequirement(type) == 'gpsbabel')
            type = type + "+"
        elsif (outputDetails.formatRequirement(type) == 'cmconvert')
            type = type + "="
        end

        printf(" %-12.12s", type);

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
    url = "http://geotoad.sourceforge.net/currentversion.php?type=#{$mode}&version=#{$VERSION}&platform=#{RUBY_PLATFORM}&rubyver=#{RUBY_VERSION}&vc=2";

    #puts "[^] Checking for latest version of GeoToad..."
    version = ShadowFetch.new(url)
    version.localExpiry=43200
    version.maxFailures = 0
    version.fetch

    if (($VERSION =~ /^(\d\.\d+\.\d+)$/) && (version.data =~ /^(\d\.\d+\.\d+): (.*)/))
        latestVersion = $1;
        releaseNotes = $2;

        if (latestVersion != $VERSION)
            puts " .------------------------------------------------------------------."
            printf("| %-66.66s |\n", "GeoToad #{latestVersion} is now available. Here are the release notes:");
            printf("| %-66.66s |\n", "");

            releaseNotes.split('|').each { |text|
               printf("|  * %-63.63s |\n", text);
            }
            puts " '------------------------------------------------------------------'"
            puts ""
            sleep(2)
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

        # only valid for zip or coordinate searches

        if @queryType == "zipcode" || @queryType == "coord"
            puts "(constraining to #{@distanceMax} miles)"
            @queryTitle = @queryTitle + " (#{@distanceMax}mi. radius)"
            @defaultOutputFile = @defaultOutputFile + "-y" + @distanceMax.to_s
            search.distance(@distanceMax.to_i)
        else
            puts
        end

        if (! search.mode(@queryType, queryArg))
            displayError "(could not determine search type for #{@queryType}, exiting)"
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
    #@filtered.removeByElement('membersonly')

    #excludedMembersTotal = beforeFilteredMembersTotal - @filtered.totalWaypoints
    #if (excludedMembersTotal > 0)
    #    displayMessage "#{excludedMembersTotal} members-only caches were filtered out (not yet supported)"
    #end

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
        @queryTitle = @queryTitle + ", terrain #{@option['terrainMax']} or lower"
        @defaultOutputFile = @defaultOutputFile + "-T" + @option['terrainMax'].to_s
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

    @cookie = login(@option['user'], @option['password'])	
    if @cookie
        displayMessage "Logged into Geocaching.com as #{@option['user']}"
    else
      displayError "Could not login"
      exit
    end
    
    displayMessage "Fetching geocache pages with #{$SLEEP} second rests between remote fetches"
    wpFiltered = @filtered.waypoints
    progress = ProgressBar.new(0, @filtered.totalWaypoints, "Fetching details")

    @detail = CacheDetails.new(wpFiltered)
    @detail.cookie = @cookie
    
    token = 0
    downloads = 0

    wpFiltered.each_key { |wid|
        token = token + 1
        detailURL = @detail.fullURL(wid)
        # This just checks to see where Shadowfetch would grab the information from.
        page = ShadowFetch.new(detailURL)
        src = page.src
     

        ret = @detail.fetch(wid)
        if (! ret)
            debug "Page for #{wpFiltered[wid]['name']} failed to be parsed, skipping."
            wpFiltered.delete(wid)
            next
        end


        message = nil
        if (page.src)
            src = page.src
            if (wpFiltered[wid]['warning'])
                message = "(cache is temp. unavailable)"
            end
            if (src == "remote")
            downloads = downloads + 1
                # somewhat obnoxious.
                #message = "(sleeping for #{$SLEEP} seconds)"
            sleep $SLEEP
            end
        else
            message = "could not fetch, private cache?)"
            wpFiltered.delete(wid)
        end

        progress.updateText(token, "\"#{wpFiltered[wid]['name']}\" from #{src} #{message}")

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

    if @option['aratingMin']
        @queryTitle = @queryTitle + ", arating #{@option['aratingMin']}+"
        @defaultOutputFile = @defaultOutputFile + "-a" + @option['aratingMin'].to_s
        @filtered.aratingMin(@option['aratingMin'].to_f)
    end

    if @option['aratingMax']
        @queryTitle = @queryTitle + ", arating #{@option['aratingMax']} or lower"
        @defaultOutputFile = @defaultOutputFile + '-A' + @option['aratingMax'].to_s
        @filtered.aratingMax(@option['aratingMax'].to_f)
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

  count = cli.downloadGeocacheList
  if count < 1
        cli.displayError "No caches found in search, exiting early."
        exit(5)
  else
        cli.displayMessage "#{count} geocaches found in defined area."
  end
  
  if (@queryType != "wid")
      cli.prepareFilter
      cli.preFetchFilter
  end

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

