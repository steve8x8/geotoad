#!/usr/local/bin/ruby
# $Id: geoweb.cgi,v 1.2 2002/04/23 22:38:25 helix Exp $

# hack to include .. into the library path.
$:.push('..')
$:.push('/code/atomdrift/geotoad')

require 'geocache/localget'
require 'geocache/search'
require 'geocache/filter'
require 'geocache/output'
require 'geocache/details'
require 'geocache/common'
require 'cgi'
require 'ftools'

$VERSION='%VERSION%'
output = Output.new
@@validFormats = output.formatList
cgi = CGI.new

input = cgi.params

## fetch code, catch this early on ##################################
if (input['type'][0] == 'fetch')
	outputDetails = Output.new
	mime = outputDetails.formatMIME(input['format'][0])
	puts "Content-type: #{mime}"
	puts "Content-disposition: attachment; filename=" + input['file'][0]
	puts ""
	input = File.new(input['file'][0]).readlines
	puts input
	exit
end
	
## Push out the real deal.
puts "Content-type: multipart/mixed;boundary=BoundaryString\n\n"
def pushOut(string)
	puts "--BoundaryString\n"
	puts "Content-type: text/html\n\n"
	puts string
	$stdout.flush
end	
## Make the Initial Query ############################
if (! $CACHE_DIR)
	pushOut "Could not find a place to use as a cache directory. Try making /var/cache"
	exit
end

outputDir = "#{$CACHE_DIR}/output/"
begin
	File.stat(outputDir).directory?
rescue
	File.makedirs(outputDir)
end


pushOut "[=] Performing #{input['type']} search for #{input['query']}<br>"
test = SearchCache.new
test.mode(input['type'], input['query'])
test.createURL
if (test.fetchAll) 
	pushOut "[.] #{test.totalWaypoints} waypoints found. Running first stage of filters.<br>"
else
pushOut "(*) No waypoints found matching query.<br>"
	exit
end

## step #1 in filtering! ############################
filtered = Filter.new(test.waypoints)
filtered.difficultyMin(input['difficultyMin'][0].to_i)
filtered.difficultyMax(input['difficultyMax'][0].to_i)
filtered.terrainMin(input['terrainMin'][0].to_i)
filtered.terrainMax(input['terrainMax'][0].to_i)
pushOut "[=] Filter complete, #{filtered.totalWaypoints} caches left. Fetching details...<br>"

## step #2 in filtering! ############################
detailed = CacheDetails.new(filtered.waypoints)

filtered= Filter.new(detailed.waypoints)
filtered.notUser(input['user'])

pushOut "[=] Filter complete, #{filtered.totalWaypoints} caches left."
if (filtered.totalWaypoints < 1)
pushOut "(*) No caches to generate output for!"
	exit
end
## generate the output ########################################
output.input(filtered.waypoints)
output.formatSelect(input['format'][0])
outputData = output.execute

## save the file #############################################

outputBasename = "geocaching-" + input['query'][0] + '.' + output.formatExtension(input['format'][0])
outputFile = outputDir + outputBasename
pushOut "Output file is now #{outputFile}"
file = open(outputFile, "w")
file.puts(outputData)
file.close
#pushOut "Output has been generated."
pushOut "[!] Output has been generated. You may fetch from <a href=\"geoweb.cgi?type=fetch&format=#{input['format']}&file=#{outputBasename}\">here</a>"

