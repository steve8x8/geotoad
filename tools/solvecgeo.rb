#!/usr/bin/env ruby

# append waypoints to GPX file
# do not replace cache coordinates!
# better suited for c:geo

# read waypoints (WPID lat lon [comment...]) from table
waypoints = Hash.new

begin
File.foreach(ARGV[0]) { |line|
  columns = line.split(/\s+/)
  name    = columns[0].upcase
  lat     = columns[1]		# sDD.DDDDDD
  lon     = columns[2]		# sDD.DDDDDD
  comment = columns[3..-1].join(" ")	# may be empty
  wpnr    = name[0..1]		# waypoint prefix & type
  case wpnr
    # final location
    when /GC/
      type = 'Final Location'
      wpnr = '99'
    # numbers: multi stages
    when /\d./
      # should be 'Virtual Stage' or 'Physical Stage'
      # but how to identify?
      type = 'Trailhead'
      wpnr.gsub!(/^0/, 'X').gsub!(/^1/, 'Y').gsub!(/^2/, 'Z')
    # extend here
    when /R./
      type = 'Reference Point'
      wpnr.gsub!(/^R/, 'Q')
  end
  waypoints[name] = {'wpnr' => wpnr, 'lat' => lat, 'lon' => lon, 'type' => type, 'comm' => comment}
}
rescue
  $stderr.puts "Cannot read #{ARGV[0].inspect}, will not modify anything"
end

# read whole gpx file
fulltext = $stdin.read
wpttext = ""
fulltext.split(/<\/wpt>/).each { |fragment|
  # walk through all cache sections in gpx file
  if fragment =~ /<name>(GC.*?)<\/name>/m
    gcid = $1
    # check whole list of wayppints read before
    # there may be more than one matching entry!
    waypoints.each_key{ |wpid|
      # is this a waypoint for this cache?
      if gcid[2..-1] == wpid[2..-1]
        # append waypoint info
        waypoint = waypoints[wpid]
        wpnr     = waypoint['wpnr']
        lat      = waypoint['lat']
        lon      = waypoint['lon']
        type     = waypoint['type']
        comment  = waypoint['comm']
        wpttext += "" +
          "<wpt lat=\"#{lat}\" lon=\"#{lon}\">\n" +
          "  <name>#{wpnr}#{wpid[2..-1]}</name>\n" +
          "  <desc>#{type} #{wpnr}</desc>\n" +
          "  <cmt>#{comment}</cmt>\n" +
          "  <sym>#{type}</sym>\n" +
          "  <type>Waypoint|#{type}</type>\n" +
          "  <gsak:wptExtension>\n" +
          "    <gsak:Parent>GC#{wpid[2..-1]}</gsak:Parent>\n" +
          "  </gsak:wptExtension>\n" +
          "</wpt>\n"
        $stderr.printf "Modified %7s: %s = %s %s -> %s (%s)\n", gcid, wpnr, lat, lon, type, comment
      end
    }
  end
}
# insert collected waypoints right before closing <gpx> tag
$stdout.puts fulltext.gsub(/<\/gpx>/, wpttext + "</gpx>")

# to be run as follows:
#
#   solvecgeo.rb solved.txt <input.gpx >output.gpx
#
# with a solved.txt file listing points by name, lat, lon (where point names are 
# constructed the same way as "normal" waypoints) as in the following fictional list:
#
# gcqmea  02.012345 53.987654 possible multi-field comment
# gcwpgf  13.543210 41.456789 use 4711 to unlock
# 0113r5p 22.555555 33.444444 back side of tree
# 0116d4t 32.888888 23.555555 T4!
# 0018k6k 42.010101 13.101010 park here
# 0118k6k 42.020202 13.202020 trailhead
