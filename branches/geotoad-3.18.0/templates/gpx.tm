template = {
  # ** The gpx.hints be removed for GeoToad 4.0, when we use a real templating engine that can do loops **
  # GPX with GroundSpeak extended attributes, modified headers
  # Successfully tested with a GArmin Oregon 300, firmware 4.10:
  # doesn't show any attributes, but doesn't complain either
  'gpx'    => {
    'ext'        => 'gpx',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML',
    'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
      "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\n" +
      "<name>" + Time.new.gmtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<email>geotoad@googlegroups.com</email>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'    => "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.XMLDate%></time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.type%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <url><%wp.url%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym><%outEntity.cacheSymbol%></sym>\n" +
      "  <type>Geocache|<%wp.fulltype%></type>\n" +
      "  <groundspeak:cache id=\"<%out.cacheID%>\" available=\"<%out.IsAvailable%>\" archived=\"<%out.IsArchived%>\" xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\">\n" +
      "  <groundspeak:name><%wpEntity.name%></groundspeak:name>\n" +
      "  <groundspeak:placed_by><%wpEntity.creator%></groundspeak:placed_by>\n" +
      "  <groundspeak:owner id=\"<%wpEntity.creator_id%>\"><%wpEntity.creator%></groundspeak:owner>\n" +
      "  <groundspeak:type><%wp.fulltype%></groundspeak:type>\n" +
      "  <groundspeak:container><%wp.size%></groundspeak:container>\n" +
      "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\n" +
      "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\n" +
      "  <groundspeak:country><%wpEntity.country%></groundspeak:country>\n" +
      "  <groundspeak:state><%wpEntity.state%></groundspeak:state>\n" +
      "  <groundspeak:attributes>\n" +
      "<%out.xmlAttrs%>" +
      "  </groundspeak:attributes>\n" +
      "  <groundspeak:short_description html=\"True\"><%out.premiumOnly%><%outEntity.warnArchiv%><%outEntity.warnAvail%>&lt;br /&gt;<%outEntity.txtAttrs%>&lt;br /&gt;<%wpEntity.shortdesc%></groundspeak:short_description>\n" +
      "  <groundspeak:long_description html=\"True\"><%outEntity.shortWpts%><%wpEntity.longdesc%></groundspeak:long_description>\n" +
      "  <groundspeak:encoded_hints><%outEntity.hintdecrypt%></groundspeak:encoded_hints>\n" +
      "  <groundspeak:logs>\n" +
      "<%out.gpxlogs%>" +
      "  </groundspeak:logs>\n" +
      "  <groundspeak:travelbugs><%out.xmlTrackables%></groundspeak:travelbugs>\n" +
      "  </groundspeak:cache>\n" +
      "</wpt>\n" +
      "<%out.xmlWpts%>",
    'templatePost'    => "</gpx>\n"
  },
}
