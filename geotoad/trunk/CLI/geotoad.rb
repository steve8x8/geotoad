#!/usr/bin/env ruby
# $Id: geotoad.rb,v 1.19 2002/08/05 03:38:51 strombt Exp $

# hack to include .. into the library path.
$:.push('..')

require 'getoptlong'
require 'geocache/common'
require 'geocache/shadowget'
require 'geocache/search'
require 'geocache/filter'
require 'geocache/output'
require 'geocache/details'


$VERSION='%VERSION%'
$SLEEP=2

common = Common.new
$TEMP_DIR=common.findTempDir

puts "% geotoad #{$VERSION} - (c) 2002 Thomas Stromberg"
puts "========================================================="
opts = GetoptLong.new(
	[ "--format",					"-f",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--output",					"-o",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--query",					"-q",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--distanceMax",				"-y",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--difficultyMin",	"-d",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--difficultyMax",	"-D",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--terrainMin",			"-t",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--terrainMax",			"-T",		GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--keyword",              "-k",       GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--cacheExpiry"     "-c",   GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--quitAfterFetch",  "-x",  GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--notFound",  "-n",  GetoptLong::NO_ARGUMENT ],
    [ "--travelBug",  "-b",  GetoptLong::NO_ARGUMENT ],
	[ "--verbose",				"-v",		GetoptLong::NO_ARGUMENT ],
	[ "--user",						"-u",		GetoptLong::OPTIONAL_ARGUMENT ]
)

output = Output.new
@@validFormats = output.formatList

def usage
	puts "syntax: geotoad [options] <search>"
	puts "    -f format for output. Valid options are:"
	outputDetails = Output.new
	@@validFormats.each { |type|
		desc = outputDetails.formatDesc(type)
		puts "          " + type + " - " + desc
	}

	puts "    -q [zip|state_id]     query type (zip by default)"
	puts "    -o [filename]         output file"
	puts "    -d [0.0-5.0]          difficulty minimum (0)"
	puts "    -D [0.0-5.0]          difficulty maximum (5)"
	puts "    -t [0.0-5.0]          terrain minimum (0)"
	puts "    -T [0.0-5.0]          terrain maximum (5)"
	puts "    -y [1-500]            distance maximum (zipcode only, defaults to 25 miles)"
	puts "    -c [0-30]             cache expiry in days"
	puts "    -x [1-500]            quit after X amount of remote fetches (200)"
    puts "    -k [keyword]          keyword search"
	puts "    -u [username]         user to filter from the lists"
	puts "    -n                    only include not found caches (virgins)"
	puts "    -v                    verbose/debug mode"

	puts ""
	puts "EXAMPLES:"
	puts "geotoad.rb 27502"
	puts "geotoad.rb -d 3 -u helixblue -f vcf -o /Volumes/Kermit/Contacts/NC.vcf -q state_id 34"
	exit
else

end


# put the stupid crap in a hash. Much nicer to deal with.
optHash = Hash.new
opts.each do |opt, arg|
	optHash[opt]=arg
end

formatType	= optHash['--format'] || 'easygps'
queryType		= optHash['--query'] || 'zip'
cacheExpiry	= optHash['--cacheExpiry'].to_i || 3
quitAfterFetch  = optHash['--quitAfterFetch'].to_i || 200

if (! ARGV[0])
	usage
	exit
else
	queryArg		= ARGV[0]
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
puts "[=] Performing #{queryType} search for #{queryArg}"
search = SearchCache.new

if optHash['--distanceMax']
	puts "[-] Constraining distance to #{optHash['--distanceMax']} miles"
	search.distance(optHash['--distanceMax'].to_i)
end

search.mode(queryType, queryArg)
search.fetchFirst
if (search.totalWaypoints)
	puts "[.] #{search.totalWaypoints} waypoints matched initial query."

	# the loop that gets all of them.
	running = 1
	downloads = 0
	while(running)
		common.debug "(download while loop)"
		# short-circuit for lack of understanding.
		if (search.totalWaypoints > search.lastWaypoint)
			common.debug "I think we need more waypoints, lets hack up a URL"
			current = search.lastWaypoint + search.returnedWaypoints
			searchURL = search.URL +  '&start=' + search.lastWaypoint.to_s
			page = ShadowFetch.new(searchURL)
			src = page.src
			puts "[o] Recieved search results for \##{search.lastWaypoint}-#{current} of #{search.totalWaypoints} (#{src})"
			if (src == "remote")
				# give the server a wee bit o' rest.
				downloads = downloads + 1
				common.debug "#{downloads} of #{quitAfterFetch} remote downloads so far"
				if downloads >= quitAfterFetch
					common.debug "quitting after #{downloads} downloads"
					#exit 4
				end
				sleep $SLEEP
			end
			running = search.fetchNext
		else
			common.debug "We have already downloaded the waypoints needed, lets get out of here"
			running = nil
		end
	end
else
	puts "(*) No waypoints found matching"
	exit
end

common.debug "pre-filter inspection of waypoints:"
waypointsExtracted = 0
search.waypoints.each_key { |wp|
    common.debug "pre-filter: #{wp}"
    waypointsExtracted = waypointsExtracted + 1
}

if (waypointsExtracted < (search.totalWaypoints - 2))
    puts "Warning: downloaded #{search.totalWaypoints} waypoints, but I can only parse #{waypointsExtracted} of them!"
end



## step #1 in filtering! ############################
puts "[=] 1st Stage Filtering Executing..."
filtered = Filter.new(search.waypoints)
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

if optHash['--notFound']
    filtered.notFound
end

if optHash['--travelBug']
    filtered.travelBug
end

puts "[=] Filter complete, #{filtered.totalWaypoints} caches left"

## step #2 in filtering! ############################
#if ((optHash['--user']) || (optHash['--format'] == 'vcard'))
	puts "[=] fetching cache details with #{$SLEEP} second rests in between gets."
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

    puts "[=] Second filtering stage is being executed"
    filtered= Filter.new(detail.waypoints)

    
    if (optHash['--user'])
         optHash['--user'].split(':').each { |user|
             filtered.notUser(user)
         }
    end

    puts "[=] Removing caches with warnings"
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
puts "[=] Generating output in #{formatType} format"
output.input(filtered.waypoints)
output.formatSelect(formatType)
outputData = output.prepare

## save the file #############################################
if (optHash['--output'])
	outputFile = optHash['--output']
	puts "[=] Saving output to #{outputFile}"
	output.commit(outputFile)
	puts "[=] Output saved Exiting."
else
	puts "[=] No output file specified by -o, displaying data:"
	puts outputData
end

