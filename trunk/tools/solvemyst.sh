#!/usr/bin/env ruby
# merge solved mysteries into GPX file
# ToDo: keep old waypoint (how?)

# first read solutions (WPID lat lon) from table
solutions = Hash.new
begin
File.foreach(ARGV[0]) { |line|
    columns = line.upcase.split(/\s+/)
    name = columns[0]
    lat = columns[1]
    lon = columns[2]
    gcid = "GC" + name[2..-1]
    wpnr = name[0..1]
    case wpnr
    when /GC/
	type = 'Traditional Cache'
    when /\d./
	type = 'Multi-cache'
    end
    solutions[gcid] = {'wpnr'=>wpnr, 'lat'=>lat, 'lon'=>lon, 'type'=>type}
}
rescue
    $stderr.puts "Cannot read #{ARGV[0].inspect}, will not modify anything"
end

# now merge into GPX (UNIX filter!)
puts $stdin.read.split(/<\/wpt>/).map { |fragment|
    if fragment =~ /<name>(GC.*?)<\/name>.*?<groundspeak:type>(Unknown Cache|Multi-cache)/m
	gcid = $1
	if fragment =~ /<groundspeak:name>(.*?)</m
	    name = $1
	end
	solution = solutions[gcid]
	if solution
	    wpnr = solution['wpnr']
	    lat = solution['lat']
	    lon = solution['lon']
	    type = solution['type']
	    fragment.gsub!(/lat="[\d\.-]+"/, "lat=\"#{lat}\"")
	    fragment.gsub!(/lon="[\d\.-]+"/, "lon=\"#{lon}\"")
	    fragment.gsub!(/(Unknown Cache|Multi-cache)</, "#{type}<")
	    fragment.gsub!(/<groundspeak:short_description[^>]*>/) { |s| s.gsub(/>/, ">[+#{wpnr}]=") }
	    $stderr.printf "Modified %7s: %s = %s %s \"%s\" -> %s\n", gcid, wpnr, lat, lon, name, type
	end
    end
    fragment
}.join("</wpt>")

# to be run as follows:
#
#   solvemyst.sh solved.txt <input.gpx >output.gpx
#
# with a solved.txt file listing points by name, lat, lon (where point names are 
# constructed the same way as "normal" waypoints) as in the following fictional list:
#
# gcqmea  02.012345 53.987654
# gcwpgf  13.543210 41.456789
# 0113r5p 22.555555 33.444444
# 0116d4t 32.888888 23.555555
# 0018k6k 42.010101 13.101010
