#!/usr/bin/env ruby
# $Id: geotoad.rb,v 1.19 2002/08/05 03:38:51 strombt Exp $

# hack to include .. into the library path.
$:.push('..')


# just in case it was never replaced.
versionID='%VERSION%'
if versionID !~ /^\d/
    $VERSION = '3.2-DEV'
else
    $VERSION = versionID.dup
end

$SLEEP=3
$SLOWMODE=350
$VERSION_URL = "http://toadstool.se/hacks/geotoad/currentversion.php?type=CLI";

require 'getoptlong'


puts "# GeoToad #{$VERSION} (#{RUBY_PLATFORM}-#{RUBY_VERSION}) - Please report bugs to geotoad@toadstool.se"
opts = GetoptLong.new(
    [ "--format",                    "-f",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--output",                    "-o",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--query",                    "-q",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--distanceMax",                "-y",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--difficultyMin",            "-d",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--difficultyMax",            "-D",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--terrainMin",                "-t",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--terrainMax",                "-T",        GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--keyword",                  "-k",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--cacheExpiry"               "-c",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--quitAfterFetch",           "-x",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--notFound",                 "-n",    GetoptLong::NO_ARGUMENT ],
    [ "--travelBug",                "-b",    GetoptLong::NO_ARGUMENT ],
    [ "--verbose",                    "-v",    GetoptLong::NO_ARGUMENT ],
    [ "--userInclude",                "-u",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--userExclude",                "-U",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--ownerInclude",                "-c",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--ownerExclude",                "-C",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--placeDateInclude",                "-p",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--placeDateExclude",                "-P",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--foundDateInclude",                "-r",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--foundDateExclude",                "-R",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--waypointLength",            "-l",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--libraryInclude",            "-L",    GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--help",                     "-h",    GetoptLong::NO_ARGUMENT ]
)

# put the stupid crap in a hash. Much nicer to deal with.
begin
    optHash = Hash.new
    opts.each do |opt, arg|
        optHash[opt]=arg
    end
rescue
    usage
    exit
end

# by request of Marc Sebastian Pelzer <marc%black-cube.net>
if optHash['--libraryInclude']
    $:.push(optHash['--libraryInclude'])
end

# toss in our own libraries.
require 'geocache/common'
require 'geocache/shadowget'
require 'geocache/searchcode'
require 'geocache/search'
require 'geocache/filter'
require 'geocache/output'
require 'geocache/details'

common = Common.new
output = Output.new

$TEMP_DIR=common.findTempDir
@@validFormats = output.formatList.sort

def usage
    puts "syntax: geotoad.rb [options] <search>"
    puts ""
    puts " -o [filename]           output file"
     puts " -f [format]             output format type, such as:"
    outputDetails = Output.new
    i=0
    print "     "
    @@validFormats.each { |type|
        desc = outputDetails.formatDesc(type)
        if (i>4)
            puts ""
            print "     "
            i=0
        end
        i=i+1


        if (desc =~ /gpsbabel/)
            type = type + "*"
	elsif (desc =~ /cmconvert/)
	    type = type + "="
        end

            printf("  %-10.10s", type);

    }
    puts ""
    puts "    * format requires gpsbabel to be installed and in PATH"
    puts "    = format requires cmconvert to be installed and in PATH"
    puts ""
    puts " -q [zip|state|coord]    query type (zip by default)"
    puts "                         [country search is broken!]"
    puts " -d [0.0-5.0]            difficulty minimum (0)"
    puts " -D [0.0-5.0]            difficulty maximum (5)"
    puts " -t [0.0-5.0]            terrain minimum (0)"
    puts " -T [0.0-5.0]            terrain maximum (5)"
    puts " -y [1-500]              distance maximum in miles (10)"
    puts " -k [keyword]            keyword (regexp) search. Use | to delimit multiple"
    puts " -c [username]           only include caches owned by this person"
    puts " -C [username]           exclude caches owned by this person"
    puts " -u [username]           only include caches found by this person"
    puts " -U [username]           exclude caches found by this person"
    puts " -p [# days]             only include caches placed in the last X days"
    puts " -P [# days]             exclude caches placed in the last X days"
    puts " -r [# days]             only include caches found in the last X days"
    puts " -R [# days]             exclude caches found in the last X days"
    puts "                         (use : to delimit multiple users!)"
    puts " -n                      only include not found caches (virgins)"
    puts " -b                      only include caches with travelbugs"
        puts " -l                      set waypoint id length. (8)"
    puts "                         Note: Garmin users can use up to 16!"
    puts ""
    puts "EXAMPLES:"
    puts "geotoad.rb 27502"
    puts "geotoad.rb -d 3 -u helixblue -f vcf -o NC.vcf -q state_id \'North Carolina\'"
    exit
else

end




formatType    = optHash['--format'] || 'gpx'
queryType        = optHash['--query'] || 'zip'
cacheExpiry    = optHash['--cacheExpiry'].to_i || 3
quitAfterFetch  = optHash['--quitAfterFetch'].to_i || 200
distanceMax = optHash['--distanceMax'] || 10

if ((! ARGV[0]) || optHash['--help'])
    if (! ARGV[0])
        puts "* You forgot to specify a #{queryType} search argument"
    end
    usage
    exit
else
    # make friendly to people who can't quote.
    queryArgList        = ARGV.join(" ")
end

if (optHash['--verbose'])

    common.debugMode=1
    common.debug "verbose mode enabled"
end

if ! @@validFormats.include?(formatType)
    puts "[*] #{formatType} is not a valid supported format."
    usage
    exit
end

## Check the version #######################
version = ShadowFetch.new($VERSION_URL)
version.shadowExpiry=0
version.localExpiry=600
version.fetch

if (version.data =~ /^(\d\.\d+\.\d+)/)
    latestVersion = $1;
    if (($VERSION !~ /DEV/) && (latestVersion != $VERSION))
        puts ""
        puts "[^] NOTE: Your version of GeoToad is old - #{latestVersion} is now available!";
        puts "[^]       Please download it from http://toadstool.se/hacks/geotoad/"
    end
end

## Make the Initial Query ############################
puts "[.] Your cache directory is " + $TEMP_DIR


# Mike Capito contributed a patch to allow for multiple
# queries. He did it as a hash earlier, I'm just simplifying
# and making it as an array because you probably don't want to
# mix multiple queryType's anyways
combinedWaypoints = Hash.new

queryArgList.split(/[:\|]/).each { |queryArg|
    print "\n[=] Performing #{queryType} search for #{queryArg} "
    search = SearchCache.new

    # only valid for zip or coordinate searches
    if queryType == "zip" || queryType == "coord"
        puts "(constraining to #{distanceMax} miles)"
        search.distance(distanceMax.to_i)
    else
        puts
    end

    if (! search.mode(queryType, queryArg))
        exit
    end

    search.fetchSearchLoop

    # this gives us support for multiple searches. It adds together the search.waypoints hashes
    # and pops them into the combinedWaypoints hash.
    combinedWaypoints.update(search.waypoints)
    combinedWaypoints.rehash
}


# Here we make sure that the amount of waypoints we've downloaded (combinedWaypoints) matches the
# amount of waypoints we found information for. This is just to check for buggy search code, and
# really doesn't make much sense.

waypointsExtracted = 0
combinedWaypoints.each_key { |wp|
    common.debug "pre-filter: #{wp}"
    waypointsExtracted = waypointsExtracted + 1
}

if (waypointsExtracted < (combinedWaypoints.length - 2))
    puts "***********************"
    puts "Warning: downloaded #{combinedWaypoints.length} waypoints, but I can only parse #{waypointsExtracted} of them!"
    puts "***********************"
end


# Prepare for the manipulation
filtered = Filter.new(combinedWaypoints)


# This is where we do a little bit of cheating. In order to avoid downloading the
# cache details for each cache to see if it's been visited, we do a search for the
# users on the include or exclude list. We then populate combinedWaypoints[wid]['visitors']
# with our discovery.

userLookups = Array.new
if (optHash['--userExclude'])
    userLookups = optHash['--userExclude'].split(':')
end

if (optHash['--userInclude'])
    userLookups = userLookups + optHash['--userInclude'].split(':')
end

userLookups.each { |user|
    search = SearchCache.new
    search.mode('user', user)
    search.fetchSearchLoop
    search.waypointList.each { |wid|
        filtered.addVisitor(wid, user)
    }
}


## step #1 in filtering! ############################
# This step filters out all the geocaches by information
# found from the searches.
puts ""

filtered = Filter.new(combinedWaypoints)
beforeFilteredMembersTotal = filtered.totalWaypoints
filtered.removeByElement('membersonly')

excludedMembersTotal = beforeFilteredMembersTotal - filtered.totalWaypoints
if (excludedMembersTotal > 0)
    puts "[=] #{excludedMembersTotal} members-only caches were filtered out (not yet supported)"
end

common.debug "[=] Filter running cycle 1, #{filtered.totalWaypoints} caches left"

if optHash['--difficultyMin']
    filtered.difficultyMin(optHash['--difficultyMin'].to_f)
end
common.debug "[=] Filter running cycle 2, #{filtered.totalWaypoints} caches left"
if optHash['--difficultyMax']
    filtered.difficultyMax(optHash['--difficultyMax'].to_f)
end
common.debug "[=] Filter running cycle 3, #{filtered.totalWaypoints} caches left"

if optHash['--terrainMin']
    filtered.terrainMin(optHash['--terrainMin'].to_f)
end
common.debug "[=] Filter running cycle 4, #{filtered.totalWaypoints} caches left"

if optHash['--terrainMax']
    filtered.terrainMax(optHash['--terrainMax'].to_f)
end

if optHash['--foundDateInclude']
    filtered.foundDateInclude(optHash['--foundDateInclude'].to_f)
end

if optHash['--foundDateExclude']
    filtered.foundDateExclude(optHash['--foundDateExclude'].to_f)
end

if optHash['--placeDateInclude']
    filtered.placeDateInclude(optHash['--placeDateInclude'].to_f)
end

if optHash['--placeDateExclude']
    filtered.placeDateExclude(optHash['--placeDateExclude'].to_f)
end

if optHash['--notFound']
    filtered.notFound
end

if optHash['--travelBug']
    filtered.travelBug
end

beforeUsersTotal = filtered.totalWaypoints
if (optHash['--userExclude'])
    optHash['--userExclude'].split(/[:\|]/).each { |user|
        filtered.userExclude(user)
    }
end

if (optHash['--userInclude'])
    optHash['--userInclude'].split(/[:\|]/).each { |user|
        filtered.userInclude(user)
    }
end

excludedUsersTotal = beforeUsersTotal - filtered.totalWaypoints
if (excludedUsersTotal > 0)
    puts "[=] User filtering removed #{excludedUsersTotal} caches from your listing."
end


puts "[=] First stage filtering complete, #{filtered.totalWaypoints} caches left"

# We should really check our local cache and shadowhosts first before
# doing this. This is just to be nice.
if (filtered.totalWaypoints > $SLOWMODE)
    puts "[!] NOTE: Because you may be downloading more than #{$SLOWMODE} waypoints"
    puts "[!]       We will sleep longer between remote downloads to lessen the load"
    puts "[!]       load on the geocaching.com webservers. You may want to constrain"
    puts "[!]       the number of waypoints to download by limiting by difficulty,"
    puts "[!]       terrain, or placement date. Please see README.txt for help."
    $SLEEP=15
end




#########################
# Here is where we fetch each geocache page
#
puts "[=] Fetching geocache pages with #{$SLEEP} second rests between remote fetches"
wpFiltered = filtered.waypoints

detail = CacheDetails.new(wpFiltered)
token = 0
wpFiltered.each_key { |wid|
    token = token + 1
    detailURL = detail.fullURL(wpFiltered[wid]['sid'])
    page = ShadowFetch.new(detailURL)
    detail.fetchWid(wid)

    # I wish I understood how this worked. I think this logic is garbage. To be revisited.
    src = page.src
    if (page.src)
        puts "[o] Fetched \"#{wpFiltered[wid]['name']}\" [#{token}/#{filtered.totalWaypoints}] from #{src}"
        if (wpFiltered[wid]['warning'])
            puts " *  Skipping: #{wpFiltered[wid]['warning']}"
        end
    elsif (src == "remote")
        downloads = downloads + 1
        common.debug "#{downloads} of #{quitAfterFetch} remote downloads so far"
        puts "  (sleeping for #{$SLEEP} seconds)"
        sleep $SLEEP
    else
        puts "[*] Could not fetch \"#{wpFiltered[wid]['name']}\" [#{token}/#{filtered.totalWaypoints}] (private cache?)"
        wpFiltered.delete(wid)
    end
}

## step #2 in filtering! ############################
# In this stage, we actually have to download all the information on the caches in order to decide
# whether or not they are keepers.

filtered= Filter.new(detail.waypoints)

# caches with warnings we choose not to include.
filtered.removeByElement('warning')

if optHash['--keyword']
    filtered.keyword(optHash['--keyword'])
end


# We filter for users again. While this may be a bit obsessive, this is in case
# our local cache is not valid.
beforeUsersTotal = filtered.totalWaypoints
if (optHash['--userExclude'])
    optHash['--userExclude'].split(/[:\|]/).each { |user|
        filtered.userExclude(user)
    }
end

if (optHash['--userInclude'])
    optHash['--userInclude'].split(/[:\|]/).each { |user|
        filtered.userInclude(user)
    }
end

excludedUsersTotal = beforeUsersTotal - filtered.totalWaypoints
if (excludedUsersTotal > 0)
    puts "[=] User filtering removed #{excludedUsersTotal} caches from your listing."
end


puts "[=] Filter complete, #{filtered.totalWaypoints} caches left"
if (filtered.totalWaypoints < 1)
    puts "(*) No caches to generate output for!"
    exit
end
## generate the output ########################################
puts ""
puts "[=] Output format selected is #{output.formatDesc(formatType)} format"
output.input(filtered.waypoints)
output.formatType=formatType
if (optHash['--waypointLength'])
    output.waypointLength=optHash['--waypointLength'].to_i
end
outputData = output.prepare("details");

## save the file #############################################
if (optHash['--output'])
    outputFile = optHash['--output']
else
    outputFile = "gtout-" + queryType + "-" + queryArgList.gsub(/[:\.]/, '_')
    if queryType == "zip" || queryType == "coord"
        outputFile = outputFile + "-y" + distanceMax.to_s
    end

    outputFile = outputFile + "." + output.formatExtension(formatType)
end

output.commit(outputFile)
puts "[=] Output saved to #{outputFile}"

