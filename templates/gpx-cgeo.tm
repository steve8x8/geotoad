template = {

  # GSAK-like GPX that can be imported into c:geo, with Additional Waypoints
  # Will produce XML validation errors because of <wpt> without lat=... lon=...
  'gpx-cgeo' => {
    'ext'  => 'gpx',
    'mime' => 'text/ascii',
    'desc' => 'GPX for c:geo, with AddWpts, also unlocated',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
        " http://www.gsak.net/xmlv1/6 http://www.gsak.net/xmlv1/6/gsak.xsd" +
# doesn't exist (2015-07-31)?
#       " http://www.cgeo.org/wptext/1/0 http://www.cgeo.org/wptext/1/0/...\"" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       " xmlns:gsak=\"http://www.gsak.net/xmlv1/6\"" +
# doesn't exist (2015-07-31)?
#       " xmlns:cgeo=\"http://www.cgeo.org/wptext/1/0\"" +
      ">\n",
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.XMLDate%></time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%></desc>\n" +
      "  <url><%wp.url%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym><%outEntity.cacheSymbol%></sym>\n" +
      "  <type>Geocache|<%wp.fulltype%></type>\n" +
      "  <groundspeak:cache id=\"<%out.cacheID%>\" available=\"<%out.IsAvailable%>\" archived=\"<%out.IsArchived%>\">\n" +
      "  <groundspeak:name><%wpEntity.name%></groundspeak:name>\n" +
      "  <groundspeak:placed_by><%wpEntity.creator%></groundspeak:placed_by>\n" +
      "  <groundspeak:owner><%wpEntity.creator%></groundspeak:owner>\n" +
      "  <groundspeak:type><%wp.fulltype%></groundspeak:type>\n" +
      "  <groundspeak:container><%wp.size%></groundspeak:container>\n" +
      "  <groundspeak:attributes>\n" +
      "<%out.xmlAttrs%>" +
      "  </groundspeak:attributes>\n" +
      "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\n" +
      "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\n" +
      "  <groundspeak:country><%wpEntity.country%></groundspeak:country>\n" +
      "  <groundspeak:state><%wpEntity.state%></groundspeak:state>\n" +
      "  <groundspeak:short_description html=\"True\">" +
       "<%out.premiumOnly%><%outEntity.warnArchiv%><%outEntity.warnAvail%>&lt;br /&gt;" +
       "<%wpEntityCgeo.shortdesc%></groundspeak:short_description>\n" +
      "  <groundspeak:long_description html=\"True\"><%wpEntityCgeo.longdesc%></groundspeak:long_description>\n" +
      "  <groundspeak:encoded_hints><%outEntityCgeo.hintdecrypt%></groundspeak:encoded_hints>\n" +
      "  <groundspeak:logs>\n" +
      "<%out.gpxlogs%>" +
      "  </groundspeak:logs>\n" +
      "  <groundspeak:travelbugs><%out.xmlTrackables%></groundspeak:travelbugs>\n" +
      "  </groundspeak:cache>\n" +
      "  <gsak:wptExtension>\n" +
      "    <gsak:IsPremium><%out.IsPremium%></gsak:IsPremium>\n" +
      "    <gsak:FavPoints><%out.FavPoints%></gsak:FavPoints>\n" +
#      "    <gsak:Watch>false</gsak:Watch>\n" +
#      "    <gsak:GcNote></gsak:GcNote>\n" +
      "  </gsak:wptExtension>\n" +
      "</wpt>\n" +
      "<%out.xmlWptsCgeo%>",
    'templatePost' =>
      "</gpx>\n"
  },

}
