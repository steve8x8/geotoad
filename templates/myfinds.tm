template = {

  # myfinds (Steve8x8) - use as follows:
  # geotoad -u $USERNAME -p ... -x myfindgpx -o myfinds.gpx -z --includeArchived -Z -q user $USERNAME
  'myfindgpx' => {
    'ext'  => 'gpx',
    'mime' => 'text/ascii',
    'desc' => 'GPX Geocaching XML (my finds)',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
       "\n" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       ">\n" +
      "<name>My Finds Pocket Query</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<email>geotoad@googlegroups.com</email>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad5%>\" lon=\"<%out.londatapad5%>\">\n" +
      "  <time><%out.cdate%>T08:00:00Z</time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.fulltype%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <url>http://www.geocaching.com/seek/cache_details.aspx?guid=<%out.guid%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym>Geocache Found</sym>\n" +
      "  <type>Geocache|<%wp.fulltype%></type>\n" +
      "  <groundspeak:cache id=\"<%out.cacheID%>\" available=\"<%out.IsAvailable%>\" archived=\"<%out.IsArchived%>\">\n" +
      "  <groundspeak:name><%wpEntity.name%></groundspeak:name>\n" +
      "  <groundspeak:placed_by><%wpEntity.creator%></groundspeak:placed_by>\n" +
      "  <groundspeak:owner id=\"<%wpEntity.creator_id%>\"><%wpEntity.creator%></groundspeak:owner>\n" +
      "  <groundspeak:type><%wp.fulltype%></groundspeak:type>\n" +
      "  <groundspeak:container><%wp.size%></groundspeak:container>\n" +
      "  <groundspeak:attributes>\n" +
      "<%out.xmlAttrs%>" +
      "  </groundspeak:attributes>\n" +
      "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\n" +
      "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\n" +
      "  <groundspeak:country><%wpEntity.country%></groundspeak:country>\n" +
      "  <groundspeak:state><%wpEntity.state%></groundspeak:state>\n" +
      "  <groundspeak:short_description html=\"True\">short</groundspeak:short_description>\n" +
      "  <groundspeak:long_description html=\"True\">long</groundspeak:long_description>\n" +
      "  <groundspeak:encoded_hints>hint</groundspeak:encoded_hints>\n" +
      "  <groundspeak:logs>\n" +
      "    <groundspeak:log id=\"<%out.logID%>\">\n" +
      "      <groundspeak:date><%out.adate%>T08:00:00Z</groundspeak:date>\n" +
      "      <groundspeak:type>Found it</groundspeak:type>\n" +
      "      <groundspeak:finder id=\"666\"><%outEntity.username%></groundspeak:finder>\n" +
      "      <groundspeak:text encoded=\"False\"></groundspeak:text>\n" +
      "    </groundspeak:log>\n" +
      "  </groundspeak:logs>\n" +
      "  <groundspeak:travelbugs />\n" +
      "  </groundspeak:cache>\n" +
      "</wpt>\n",
    'templatePost' =>
      "</gpx>\n"
  },

  'myfindlist' => {
    'ext'  => 'lst',
    'mime' => 'text/plain',
    'desc' =>     'Table, whitespace delimited (my finds)',
    'templatePre'  => "",
    'templateWP'   =>
      "<%out.wid%>\t" +
      "<%out.latdatapad5%> <%out.londatapad5%> " +
      "<%wp.type%>\t" +
      "<%out.adate%>\n"
  },

  # yourfinds (Steve8x8) - use as follows:
  # geotoad -u $USERNAME -p ... -x yourfindgpx -o yourfinds.gpx -z -Z --includeArchived -q user $ANOTHERUSERNAME
  'yourfindgpx' => {
    'ext'  => 'gpx',
    'mime' => 'text/ascii',
    'desc' => 'GPX Geocaching XML (user finds)',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\'?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
       "\n" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       ">\n" +
      "<name>My Finds Pocket Query</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<email>geotoad@googlegroups.com</email>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.cdate%>T08:00:00Z</time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.fulltype%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <url>http://www.geocaching.com/seek/cache_details.aspx?guid=<%out.guid%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym>Geocache Found</sym>\n" +
      "  <type>Geocache|<%wp.fulltype%></type>\n" +
      "  <groundspeak:cache id=\"<%out.cacheID%>\" available=\"<%out.IsAvailable%>\" archived=\"<%out.IsArchived%>\">\n" +
      "  <groundspeak:name><%wpEntity.name%></groundspeak:name>\n" +
      "  <groundspeak:placed_by><%wpEntity.creator%></groundspeak:placed_by>\n" +
      "  <groundspeak:owner id=\"<%wpEntity.creator_id%>\"><%wpEntity.creator%></groundspeak:owner>\n" +
      "  <groundspeak:type><%wp.fulltype%></groundspeak:type>\n" +
      "  <groundspeak:container><%wp.size%></groundspeak:container>\n" +
      "  <groundspeak:attributes>\n" +
      "<%out.xmlAttrs%>" +
      "  </groundspeak:attributes>\n" +
      "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\n" +
      "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\n" +
      "  <groundspeak:country><%wpEntity.country%></groundspeak:country>\n" +
      "  <groundspeak:state><%wpEntity.state%></groundspeak:state>\n" +
      "  <groundspeak:short_description html=\"True\">short</groundspeak:short_description>\n" +
      "  <groundspeak:long_description html=\"True\">long</groundspeak:long_description>\n" +
      "  <groundspeak:encoded_hints>hint</groundspeak:encoded_hints>\n" +
      "  <groundspeak:logs>\n" +
      "    <groundspeak:log id=\"<%out.logID%>\">\n" +
      "      <groundspeak:date><%out.mdate%>T08:00:00Z</groundspeak:date>\n" +
      "      <groundspeak:type>Found it</groundspeak:type>\n" +
      "      <groundspeak:finder id=\"666\"><%outEntity.username%></groundspeak:finder>\n" +
      "      <groundspeak:text encoded=\"False\"></groundspeak:text>\n" +
      "    </groundspeak:log>\n" +
      "  </groundspeak:logs>\n" +
      "  <groundspeak:travelbugs />\n" +
      "  </groundspeak:cache>\n" +
      "</wpt>\n",
    'templatePost' =>
      "</gpx>\n"
  },

  'yourfindlist' => {
    'ext'  => 'lst',
    'mime' => 'text/plain',
    'desc' =>     'Table, whitespace delimited (user finds)',
    'templatePre'  => "",
    'templateWP'   =>
      "<%out.wid%>\t" +
      "<%out.latdatapad5%> <%out.londatapad5%> " +
      "<%wp.type%>\t" +
      "<%out.mdate%>\n"
  },

}
