#!/usr/bin/env ruby
# $Id: geotoad.rb,v 1.19 2002/08/05 03:38:51 strombt Exp $

# hack to include .. into the library path.
$:.push('..')


# just in case it was never replaced.
versionID='%VERSION%'
if versionID !~ /^\d/
    $VERSION = '3.0-CURRENT'
else
    $VERSION = versionID.dup
end

$SLEEP=3
$SLOWMODE=350
$VERSION_URL = "http://toadstool.se/hacks/geotoad/currentversion.php?type=CLI";

require 'getoptlong'
require 'geocache/common'
require 'geocache/shadowget'
require 'geocache/searchcode'
require 'geocache/search'
require 'geocache/filter'
require 'geocache/output'
require 'geocache/details'


common = Common.new
$TEMP_DIR=common.findTempDir

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
    [ "--help",                     "-h",    GetoptLong::NO_ARGUMENT ]
)

output = Output.new
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
    puts " -y [1-500]              distance maximum (10)"
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


## Make the Initial Query ############################
puts "[.] Your cache directory is " + $TEMP_DIR

## Check the version
version = ShadowFetch.new($VERSION_URL)
version.shadowExpiry=0
version.localExpiry=600
version.fetch

if (version.data =~ /^(\d\.\d+\.\d+)/)
    latestVersion = $1;
    if (latestVersion != $VERSION)
        puts ""
        puts "[^] NOTE: Your version of GeoToad is old - #{latestVersion} is now available!";
        puts "[^]       Please download it from http://toadstool.se/hacks/geotoad/"
    end
end


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

    search.fetchFirst
    if (search.totalWaypoints)
        puts "[.] #{search.totalWaypoints} waypoints matched #{queryArg} query, recieved results for 1-#{search.lastWaypoint}."

        # the loop that gets all of them.
        running = 1
        downloads = 0
        resultsPager = 5
        while(running)
            # short-circuit for lack of understanding.
            totalPages = search.totalPages
            currentPage = search.currentPage
            common.debug "(download while loop - #{currentPage} of #{totalPages})"

            if (totalPages > currentPage)
                lastPage = currentPage
                # I don't think this does anything.
                page = ShadowFetch.new(search.URL)
                running = search.fetchNext
                src = page.src
                # update it.
                currentPage = search.currentPage
                puts "[o] Recieved search page #{currentPage} of #{totalPages} (#{src})"

                if (currentPage <= lastPage)
                    puts "[*] Logic error. I was at page #{lastPage} before, why am I at #{currentPage} now?"
                    exit
                end

                if (src == "remote")
                    # give the server a wee bit o' rest.
                    downloads = downloads + 1
                    common.debug "#{downloads} of #{quitAfterFetch} remote downloads so far"
                    if downloads >= quitAfterFetch
                        common.debug "quitting after #{downloads} downloads"
                        #exit 4
                    end
                   # half the rest for this.
                     common.debug "sleeping"
                    sleep ($SLEEP / 2).to_i
                end
            else
                common.debug "We have already downloaded the waypoints needed, lets get out of here"
                running = nil
            end # end totalPages if
        end # end while(running)
    else
        puts "(*) No waypoints found. Possible error fetching?"
        exit
    end

    # this gives us support for multiple searches.
    combinedWaypoints.update(search.waypoints)
    combinedWaypoints.rehash
}

common.debug "pre-filter inspection of waypoints:"
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



## step #1 in filtering! ############################
puts ""
#puts "[=] 1st Stage Filtering Executing..."
filtered = Filter.new(combinedWaypoints)
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

if (optHash['--ownerExclude'])
    optHash['--ownerExclude'].split(':').each { |owner|
        filtered.ownerExclude(owner)
    }
end

if (optHash['--ownerInclude'])
    optHash['--ownerInclude'].split(':').each { |owner|
        filtered.ownerInclude(owner)
    }
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

## step #2 in filtering! ############################
#if ((optHash['--user']) || (optHash['--format'] == 'vcard'))
    puts "[=] Fetching geocache pages with #{$SLEEP} second rests between remote fetches"
    wpFiltered = filtered.waypoints

    # all of this junk is so we can give real status updates for non-CLI frontends
    # but this is the demo code, so we use it!
    detail = CacheDetails.new(wpFiltered)
    token = 0
    wpFiltered.each_key { |wid|
        token = token + 1
        #detailURL = ShadowFetch.detail.baseURL + wpFiltered[wid]['sid'].to_s
        detailURL = detail.fullURL(wpFiltered[wid]['sid'])
        page = ShadowFetch.new(detailURL)
        detail.fetchWid(wid)
        src = page.src
        if (page.src)
            puts "[o] Fetched \"#{wpFiltered[wid]['name']}\" [#{token}/#{filtered.totalWaypoints}] from #{src}"
            if (wpFiltered[wid]['warning'])
                puts " *  Skipping: #{wpFiltered[wid]['warning']}"
            end
        elsif (src == "remote")
                downloads = downloads + 1
                common.debug "#{downloads} of #{quitAfterFetch} remote downloads so far"
                if downloads >= quitAfterFetch
                    common.debug "quitting after #{downloads} downloads"
                    #exit 4
                end
            puts "  (sleeping for #{$SLEEP} seconds)"
            sleep $SLEEP
        else
            puts "[*] Could not fetch \"#{wpFiltered[wid]['name']}\" [#{token}/#{filtered.totalWaypoints}] (private cache?)"
            wpFiltered.delete(wid)
        end
    }

    #puts "[=] Second filtering stage is being executed"
    filtered= Filter.new(detail.waypoints)
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

    #puts "[=] Removing caches with warnings"
    # caches with warnings we choose not to include.
    filtered.removeByElement('warning')
    if optHash['--keyword']
        filtered.keyword(optHash['--keyword'])
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

