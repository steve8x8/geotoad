template = {

  # templates for separate output of caches and add.wpts for GSAK use
  'gpx-gsak' => {
    'ext'  => 'gpx',
    'desc' => 'GPX for GSAK, without AddWpts',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad <%outEntity.version%>\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
        " http://www.gsak.net/xmlv1/6 http://www.gsak.net/xmlv1/6/gsak.xsd" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       " xmlns:gsak=\"http://www.gsak.net/xmlv1/6\"" +
      ">\n" +
      "<name>Geocaches</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")  + "</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.ctime%></time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.type%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <url><%wp.url%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym><%outEntity.cacheSymbol%></sym>\n" +
      "  <type>Geocache|<%wp.fulltype%></type>\n" +
      "  <groundspeak:cache id=\"<%out.cacheID%>\" available=\"<%out.IsAvailable%>\" archived=\"<%out.IsArchived%>\">\n" +
      "  <groundspeak:name><%wpEntity.name%></groundspeak:name>\n" +
      "  <groundspeak:placed_by><%wpEntity.creator%></groundspeak:placed_by>\n" +
      "  <groundspeak:owner><%wpEntity.creator%></groundspeak:owner>\n" +
      "  <groundspeak:type><%wp.fulltype%></groundspeak:type>\n" +
      "  <groundspeak:container><%out.csize%></groundspeak:container>\n" +
      "  <groundspeak:attributes>\n" +
       "<%out.xmlAttrs%>" +
       "  </groundspeak:attributes>\n" +
      "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\n" +
      "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\n" +
      "  <groundspeak:country><%wpEntity.country%></groundspeak:country>\n" +
      "  <groundspeak:state><%wpEntity.state%></groundspeak:state>\n" +
      "  <groundspeak:short_description html=\"True\">" +
       "<%out.premiumOnly%><%outEntity.warnArchiv%><%outEntity.warnAvail%>&lt;br /&gt;" +
       "<%outEntity.txtAttrs%>&lt;br /&gt;" +
       "<%wpEntity.shortdesc%>" +
       "</groundspeak:short_description>\n" +
      "  <groundspeak:long_description html=\"True\">" +
       "<%outEntity.shortWpts%>" +
       "<%wpEntity.longdesc%>" +
       "<%wpEntityNone.gallery%>" +
       "</groundspeak:long_description>\n" +
      "  <groundspeak:encoded_hints><%outEntity.hintdecrypt%></groundspeak:encoded_hints>\n" +
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
      "</wpt>\n",
    'templatePost' =>
      "</gpx>\n"
  },

  'gpx-wpts' => {
    'ext'  => 'wgpx',
    'desc' => 'GPX for GSAK, AddWpts only',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad <%outEntity.version%>\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
        " http://www.gsak.net/xmlv1/6 http://www.gsak.net/xmlv1/6/gsak.xsd" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       " xmlns:gsak=\"http://www.gsak.net/xmlv1/6\"" +
      ">\n" +
      "<name>Waypoints</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")  + "</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'   =>
      "<%out.xmlWptsGsak%>",
    'templatePost' =>
      "</gpx>\n"
  },

  # Same as above, but including locationless waypoints
  # Will produce XML validation errors because of <wpt> without lat=... lon=...
  'gpx-wpts0' => {
    'ext'  => 'wgpx',
    'desc' => 'GPX for GSAK, AddWpts only, also unlocated',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad <%outEntity.version%>\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
        " http://www.gsak.net/xmlv1/6 http://www.gsak.net/xmlv1/6/gsak.xsd" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       " xmlns:gsak=\"http://www.gsak.net/xmlv1/6\"" +
      ">\n" +
      "<name>Waypoints</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")  + "</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'   =>
      "<%out.xmlWptsCgeo%>",
    'templatePost' =>
      "</gpx>\n"
  },

}
