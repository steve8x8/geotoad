#!/usr/bin/env ruby
# append waypoints to GPX file
# do not replace cache coordinates!
# better suited for c:geo

#read waypoints (WPID lat lon) from table
waypoints = Hash.new
begin
File.foreach(ARGV[0]) { |line|
    columns = line.upcase.split(/\s+/)
    name = columns[0]
    lat  = columns[1]
    lon  = columns[2]
    comm = columns[3]
    wpnr = name[0..1]
    wpid = name[0..-1]
    case wpnr
      when /GC/
	type = 'Final Location'
	wpnr = '99'
	
      when /\d./
	type = 'Trailhead'
	wpnr.gsub!(/^0/, 'X')
    end
    waypoints[wpid] = {'wpnr'=>wpnr, 'lat'=>lat, 'lon'=>lon, 'type'=>type, 'comm'=>comm}
}
rescue
    $stderr.puts "Cannot read #{ARGV[0].inspect}, will not modify anything"
end

fulltext = $stdin.read
wpttext = ""
wpids = Array.new
fulltext.split(/<\/wpt>/).each { |fragment|
    if fragment =~ /<name>(GC.*?)<\/name>/m
	gcid = $1
	waypoints.each_key{ |wpid|
	    # is this a waypoint for this cache?
	    if gcid[2..-1] == wpid[2..-1]
		# append waypoint info
		waypoint = waypoints[wpid]
		wpnr = waypoint['wpnr']
		lat  = waypoint['lat']
		lon  = waypoint['lon']
		type = waypoint['type']
		comm = waypoint['comm']
		wpttext += "" +
		    "<wpt lat=\"#{lat}\" lon=\"#{lon}\">\n" +
		    "  <name>#{wpnr}#{wpid[2..-1]}</name>\n" +
		    "  <desc>#{type} #{wpnr}</desc>\n" +
		    "  <cmt>#{comm}</cmt>\n" +
		    "  <sym>#{type}</sym>\n" +
		    "  <type>Waypoint|#{type}</type>\n" +
		    "  <gsak:wptExtension>\n" +
		    "    <gsak:Parent>GC#{wpid[2..-1]}</gsak:Parent>\n" +
		    "  </gsak:wptExtension>\n" +
# this breaks c:geo import!
#		    "  <cgeo:userdefined>true</cgeo:userdefined>\n" +
		    "</wpt>\n"
		$stderr.printf "Modified %7s: %s = %s %s -> %s\n", gcid, wpnr, lat, lon, type
		wpids.push wpid
	    end
	}
    end
}
$stdout.puts fulltext.gsub(/<\/gpx>/, wpttext + "</gpx>")

# to be run as follows:
#
#   solvecgeo.sh solved.txt <input.gpx >output.gpx
#
# with a solved.txt file listing points by name, lat, lon (where point names are 
# constructed the same way as "normal" waypoints) as in the following fictional list:
#
# gcqmea  02.012345 53.987654
# gcwpgf  13.543210 41.456789
# 0113r5p 22.555555 33.444444
# 0116d4t 32.888888 23.555555
# 0018k6k 42.010101 13.101010
# 0118k6k 42.020202 13.202020
