#!/usr/bin/env ruby
# $Id: geotoad.rb,v 1.19 2002/08/05 03:38:51 strombt Exp $

# hack to include .. into the library path.
$:.push('..')

require 'getoptlong'
require 'geocache/common'
require 'geocache/shadowget'
require 'geocache/searchcode'
require 'geocache/search'
require 'geocache/filter'
require 'geocache/output'
require 'geocache/details'


$VERSION='%VERSION%'
$SLEEP=3

common = Common.new
$TEMP_DIR=common.findTempDir

puts "% geotoad #{$VERSION} - (c) 2003 Thomas Stromberg"
opts = GetoptLong.new(
	[ "--format",					"-f",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--output",					"-o",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--query",					"-q",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--distanceMax",				"-y",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--difficultyMin",	        "-d",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--difficultyMax",	        "-D",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--terrainMin",			    "-t",		GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--terrainMax",			    "-T",		GetoptLong::OPTIONAL_ARGUMENT ],
    [ "--keyword",                  "-k",    GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--cacheExpiry"               "-c",    GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--quitAfterFetch",           "-x",    GetoptLong::OPTIONAL_ARGUMENT ],
	[ "--notFound",                 "-n",    GetoptLong::NO_ARGUMENT ],
    [ "--travelBug",                "-b",    GetoptLong::NO_ARGUMENT ],
	[ "--verbose",				    "-v",    GetoptLong::NO_ARGUMENT ],
	[ "--user",						"-u",    GetoptLong::OPTIONAL_ARGUMENT ],
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
		end
	        printf("  %-8.8s", type);

	}
    puts ""
    puts "    * format requires gpsbabel to be installed and in PATH"
    puts ""
	puts " -q [zip|state|country]  query type (zip by default)"
	puts " -d [0.0-5.0]            difficulty minimum (0)"
	puts " -D [0.0-5.0]            difficulty maximum (5)"
	puts " -t [0.0-5.0]            terrain minimum (0)"
	puts " -T [0.0-5.0]            terrain maximum (5)"
	puts " -y [1-500]              distance maximum (15)"
    puts " -k [keyword]            keyword (regexp) search. Use | to delimit multiple"
	puts " -u [username]           filter out caches found by username. "
    puts "                         Use : to delimit multiple users"
	puts " -n                      only include not found caches (virgins)"
    puts " -b                      only include caches with travelbugs"

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

formatType	= optHash['--format'] || 'easygps'
queryType		= optHash['--query'] || 'zip'
cacheExpiry	= optHash['--cacheExpiry'].to_i || 3
quitAfterFetch  = optHash['--quitAfterFetch'].to_i || 200
distanceMax = optHash['--distanceMax'] || 15

if ((! ARGV[0]) || optHash['--help'])
	if (! ARGV[0])
		puts "* You forgot to specify a #{queryType} search argument"
	end
	usage
	exit
else
    # make friendly to people who can't quote.
	queryArg		= ARGV.join(" ")
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
print "[=] Performing #{queryType} search for #{queryArg} "
search = SearchCache.new


# only valid for zip searches
if queryType == "zip"
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
	puts "[.] #{search.totalWaypoints} waypoints matched initial query, recieved results for 1-#{search.lastWaypoint}."

	# the loop that gets all of them.
	running = 1
	downloads = 0
    resultsPager = 5
	while(running)
		common.debug "(download while loop)"
		# short-circuit for lack of understanding.
		if (search.totalWaypoints > search.lastWaypoint)
            lastWaypoint=search.lastWaypoint

			common.debug "I think we need more waypoints, lets hack up a URL"
			current = search.lastWaypoint + search.returnedWaypoints

            # for the new crap that geocaching.com throws in
            postVars = search.postVars
            postVars['__EVENTTARGET']="ResultsPager$_ctl#{resultsPager}"

			# legacy
            #searchURL = search.URL +  '&start=' + search.lastWaypoint.to_s
            searchURL = search.postURL
			page = ShadowFetch.new(searchURL)
            page.postVars=postVars
            # very short expiry time for the search index.
            page.shadowExpiry=60000
            page.localExpiry=43200
            common.debug "Going to fetch the page for real now"
            page.fetch

			src = page.src
			puts "[o] Recieved search results for \##{search.lastWaypoint}-#{current} of #{search.totalWaypoints} (#{src})"
            if (search.lastWaypoint <= lastWaypoint)
                puts "[*] Logic error. I was at #{lastWaypoint} before, why am I at #{search.lastWaypoint} now?"
                exit
            end

            #exit
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

    puts "[=] Second filtering stage is being executed"
    filtered= Filter.new(detail.waypoints)


    if (optHash['--user'])
         optHash['--user'].split(':').each { |user|
             filtered.notUser(user)
         }
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
puts "[=] Generating output in #{formatType} format"
output.input(filtered.waypoints)
output.formatSelect(formatType)
outputData = output.prepare("details");

## save the file #############################################
if (optHash['--output'])
    outputFile = optHash['--output']
else
    outputFile = "geotoad-output." + output.formatExtension(formatType)
    puts " -  No output file specified, defaulting to to #{outputFile}"
end

puts "[=] Saving output to #{outputFile}"
output.commit(outputFile)

