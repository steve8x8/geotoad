# This is our dump templating engine. It only handles really simple text formats at the moment.
# GeoToad 4.0 will have a plugins architecture that replaces this.

$Format = {
  # revised using http://mpickering.homeip.net/software/gpspoint_to_gpx.py
  # see also http://mirror.rosalab.ru/rosa/rosa2012.1/repository/SRPMS/contrib/release/gpspoint-2.030521-7.src.rpm
  'gpspoint'    => {
    'ext'        => 'gpd',
    'mime'    => 'application/gpspoint',
    'desc'    => 'gpspoint datafile',
    'templatePre'    => "GPSPOINT DATA FILE\ntype=\"fileinfo\"  version=\"1.00\"\n" +
      "type=\"programinfo\" program=\"geotoad\" version=\"0.0\"\n" +
      "type=\"waypointlist\"\n",
    'templateWP'     => "type=\"waypoint\" " +
      "latitude=\"<%out.latdatapad5%>\" longitude=\"<%out.londatapad5%>\" " +
      "name=\"<%out.id%>\" comment=\"<%wp.name%> (Geocache:<%wp.type%>/<%wp.size%>/D<%wp.difficulty%>/T<%wp.terrain%>)\" " +
      "symbol=\"flag\"  display_option=\"symbol+name\"\n",
    'templatePost'   => "type=\"waypointlistend\"\n",
  },

  # use gpsbabel to create gpspoint file from gpx
  'gpspoint2' => {
    'ext'         => 'gpd',
    'mime'        => 'application/gpspoint',
    'desc'        => 'gpspoint datafile created by gpsbabel',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o xcsv,style=STYLEFILE -F OUTFILE',
    'filter_style'=> "#STYLEFILE: (inpired by Mike Pickering, 6/19/2005)\n" +
                     "DESCRIPTION             gpspoint format\n" +
                     "FIELD_DELIMITER         SPACE\n" +
                     "RECORD_DELIMITER        NEWLINE\n" +
                     "BADCHARS                ^\n" +
                     "PROLOGUE GPSPOINT DATA FILE\n" +
                     "PROLOGUE type=\"waypointlist\" comment=\"GeoToad\"\n" +
                     "OFIELD  CONSTANT,       \"type=\"waypoint\"\", \"%s\"\n" +
                     "OFIELD  LAT_DECIMAL,    \"\", \"latitude=\"%.5f\"\"\n" +
                     "OFIELD  LON_DECIMAL,    \"\", \"longitude=\"%.5f\"\"\n" +
                     "OFIELD  SHORTNAME,      \"\", \"name=\"%s\"\"\n" +
                     "OFIELD  URL_LINK_TEXT,  \"\", \"comment=\"%s\"\n" +
                     "OFIELD  ICON_DESCR,     \"\", \"(%s\"\n" +
                     "OFIELD GEOCACHE_TYPE,   \"\", \":%-.5s\", \"no_delim_before,optional\"\n" +
                     "OFIELD GEOCACHE_CONTAINER, \"\", \"/%-.5s\", \"no_delim_before,optional\"\n" +
                     "OFIELD GEOCACHE_DIFF,   \"\", \"/D%3.1f\", \"no_delim_before,optional\"\n" +
                     "OFIELD GEOCACHE_TERR,   \"\", \"/T%3.1f\", \"no_delim_before,optional\"\n" +
                     "OFIELD  CONSTANT,       \")\", \"%s\"\", \"no_delim_before\"\n" +
                     "OFIELD  CONSTANT,       \"symbol=\"flag\"\", \"%s\"\n" +
                     "OFIELD  CONSTANT,       \"display_option=\"symbol+name\"\", \"%s\"\n" +
                     "EPILOGUE type=\"waypointlistend\"\n"
  },

  'easygps' => {
    'ext'        => 'loc',
    'mime'    => 'application/easygps',
    'desc'    => 'Geocaching.com .loc XML file',
    'templatePre'    => "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><loc version=\"1.0\" src=\"EasyGPS\">",
    'templateWP'    => "<waypoint><name id=\"<%out.id%>\"><![CDATA[<%wp.name%>]]></name>" +
      "<coord lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\"/>" +
      "<type>geocache</type><link text=\"Cache Details\"><%wp.url%></link></waypoint>",
    'templatePost'    => '</loc>',
  },

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
      "  <groundspeak:short_description html=\"True\"><%outEntity.warnArchiv%><%outEntity.warnAvail%>&lt;br /&gt;<%outEntity.txtAttrs%>&lt;br /&gt;<%wpEntity.shortdesc%></groundspeak:short_description>\n" +
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

  # Two templates for separate output of caches and add.wpts for GSAK use
  'gpx-gsak'    => {
    'ext'        => 'gpx',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML for GSAK, without Additional Waypoints',
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
      "  <groundspeak:short_description html=\"True\"><%outEntity.warnArchiv%><%outEntity.warnAvail%>&lt;br /&gt;<%outEntity.txtAttrs%>&lt;br /&gt;<%wpEntity.shortdesc%></groundspeak:short_description>\n" +
      "  <groundspeak:long_description html=\"True\"><%outEntity.shortWpts%><%wpEntity.longdesc%></groundspeak:long_description>\n" +
      "  <groundspeak:encoded_hints><%outEntity.hintdecrypt%></groundspeak:encoded_hints>\n" +
      "  <groundspeak:logs>\n" +
      "<%out.gpxlogs%>" +
      "  </groundspeak:logs>\n" +
      "  <groundspeak:travelbugs><%out.xmlTrackables%></groundspeak:travelbugs>\n" +
      "  </groundspeak:cache>\n" +
      "</wpt>\n",
    'templatePost'    => "</gpx>\n"
  },

  'gpx-wpts'    => {
    'ext'        => 'wgpx',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML for GSAK, only Additional Waypoints',
    'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
      "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0 http://www.groundspeak.com/cache/1/0/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\n" +
      "<name>" +
        "Waypoints for Cache Listings Generated from Geocaching.com, geotoad " +
        Time.new.gmtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<email>geotoad@googlegroups.com</email>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'    => "<%out.xmlWpts%>",
    'templatePost'    => "</gpx>\n"
  },

  # Modified GPX XML for PathAway, which doesn't support HTML content in gpx files.
  # Since <groundspeak:...> tags are ignored, so we have to include all the necessary information in the <desc> tag
  # Contributed by Tris Sethur, Sep 2011
  'gpx-pa'    => {
    'ext'        => 'gpx',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML for PathAway',
    'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
      "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\n" +
      "<name>" + Time.new.gmtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n",
    'templateWP'    => "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <name>" + '<![CDATA[' + "<%outEntity.id%>" + ']]>' + "</name>\n" +
      "  <desc>" + '<![CDATA[' +
        "<%outEntity.wid%>:<%wpText.name%>\n=== <%wp.type%> (D:<%wp.difficulty%>/T:<%wp.terrain%>/F:<%wp.funfactor%>/S:<%wp.size%>) by <%wpText.creator%>\n" +
        "<%outText.warnArchiv%><%outText.warnAvail%><%outText.txtAttrs%>\n" +
        "<%wpText.shortdesc%>\nDescription: <%wpText.longdesc%>\n" +
        "Hint:<%outText.hint%>" + ']]>' +
        "</desc>\n" +
      "  <sym><%outEntity.cacheSymbol%></sym>\n" +
      "</wpt>\n" +
      "<%out.xmlWpts%>",
    'templatePost'    => "</gpx>\n"
  },

  'html'    => {
    'ext'        => 'html',
    'mime'    => 'text/html',
    'desc'    => 'Simple HTML',
    'templatePre' => "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n" +
      "<html><head>\n<title><%out.title%></title>\n" +
      "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n" + "</head>\n" +
      "<body link=\"#000099\" vlink=\"#000044\" alink=\"#000099\">\n" +
      "<h3><%out.title%></h3>" +
      "<b><font color=\"#111111\">&Oslash;</font></b> archived&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#CC1111\">&#x229e;</font></b> marked as \"temporarily unavailable\"<br>" +
      "<b><font color=\"#11CC11\">&euro;</font></b> have travelbugs&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#9900CC\">&infin;</font></b> never been found&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#999922\">&sect;</font></b> terrain rating of 3.5+&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#440000\">&uarr;</font></b> difficulty rating of 3.5+&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#66FF66\">+</font></b> fav factor of 3.0+&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#BB6666\">&hearts;</font></b> fun factor of 3.5+<br>" +
      # Not yet ready for consumption
    #"<b><font color=\"#333333\">--</font></b> comments seem negative&nbsp;&nbsp;&nbsp;" +
    #"<b><font color=\"#000000\">++</font></b> comments seem very positive" +
      "<br>\n",
    'templateIndex' => "* <a href=\"#<%out.wid%>\"><%wpEntity.name%></a><br>",
    'usesLocation' => true,
    'templateWP'    =>
      "\n\n<hr noshade size=\"1\">\n" +
      "<h3><a name=\"<%out.wid%>\"></a><font color=\"#000099\"><%out.symbols%><a href=\"<%wp.url%>\"><%wp.name%></a></font> by <font color=\"#555555\"><%wpEntity.creator%></font> <font color=\"#444444\">(<%out.id%>)</font></h3>\n" +
      "<a href=\"<%out.maps_url%>\"><%wp.latwritten%> <%wp.lonwritten%></a> <i>near <%out.location%></i><br>" +
      "<font color=\"#339933\"><%wp.type%> (<%wp.size%>) D<%wp.difficulty%>/T<%wp.terrain%> (F<%wp.funfactor%>) Fav<%wp.favfactor%>(<%wp.favorites%>/<%wp.foundcount%>) &rarr;<%out.relativedistance%><br>" +
      "Placed: <%out.cdate%> Last comment: <%wp.last_find_days%> days ago (<%wp.last_find_type%>)</font><br>\n" +
      "Age of information: <%wp.ldays%> days<br>\n" +
      "Attributes: <%out.txtAttrs%><br>\n" +
      "<div>" + # catch runaway stuff like <center>
      "<p><%wp.additional_raw%><%wp.shortdesc%></p>\n" + # font size inside tables?
      "<p><%wp.longdesc%></p>\n" +
      "</div>\n" +
      "<p><font color=\"#555555\"><i><%outEntity.hintdecrypt%></i></font></p>\n" +
      "<div>" + # catch runaway stuff like <center>
      "<p><font color=\"#330000\" size=\"-1\"><%out.htmllogs%></font></p>\n" +
      "</div>\n",
    'templatePost'    => "</body></html>"
  },

  'text'    => {
    'ext'        => 'txt',
    'mime'    => 'text/plain',
    'desc'    =>     'Plain ASCII',
    'templatePre' =>  "== <%out.title%>\n\n",
    'templateWP'    => "\n" +
      "----------------------------------------------------------------\n" +
      "=> <%wpText.name%> (<%out.wid%>) by <%wpText.creator%> <=\n" +
      "----------------------------------------------------------------\n\n" +
      "Lat: <%wp.latwritten%> Lon: <%wp.lonwritten%>\n" +
      "Difficulty: <%wp.difficulty%>, Terrain: <%wp.terrain%>, FunFactor: <%wp.funfactor%>, FavFactor: <%wp.favfactor%>\n" +
      "Type/Size: <%wp.type%> (<%wp.size%>), Distance: <%out.relativedistance%>\n" +
      "Creation: <%out.cdate%>, Last comment: <%wp.last_find_days%> days ago (<%wp.last_find_type%>)\n\n" +
      "Age of info: <%wp.ldays%> days\n" +
      "Attributes: <%out.txtAttrs%>\n" +
      "State: <%out.warnArchiv%><%out.warnAvail%>\n" +
      "Short: <%wpText.shortdesc%>\n" +
      "Long:\n<%wpText.longdesc%>\n\n" +
      "Hint: <%outEntity.hintdecrypt%>\n\n" +
      "Logs:\n<%out.textlogs%>\n"
  },

  'tab'    => {
    'ext'        => 'txt',
    'mime'    => 'text/plain',
    'desc'    =>     'Tab Delimited (GPS Connect)',
    'templatePre' => "",
    'templateWP'    => "<%out.id%>\t<%out.latdatapad6%>\t<%out.londatapad6%>\t0\n"
  },

  'csv'    => {
    'ext'        => 'txt',
    'mime'    => 'text/plain',
    'desc'    => 'CSV for spreadsheet imports',
    'templatePre' => "\"Name\",\"Waypoint ID\",\"Creator\",\"Difficulty\",\"Terrain\"," +
      "\"Latitude\",\"Longitude\",\"Type\",\"Size\",\"Creation Date\",\"Details\"\n",
    'templateWP'    => "\"<%wp.name%>\",\"<%out.wid%>\",\"<%wp.creator%>\"," +
      "<%wp.difficulty%>,<%wp.terrain%>,\"<%wp.latwritten%>\",\"<%wp.lonwritten%>\"," +
      "\"<%wp.type%>\",\"<%wp.size%>\",\"<%out.cdate%>\",\"<%outText.short_desc%> <%outText.long_desc%>\"\n"
  },

  'gpsman' => {
    'ext'        => 'gpm',
    'mime'    => 'application/gpsman',
    'desc'    => 'GPSman datafile',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsman -F OUTFILE'
  },

  'mapsend' => {
    'ext'        => 'mps',
    'mime'    => 'application/mapsend',
    'desc'    => 'Magellan MapSend software',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx  -f INFILE -o mapsend -F OUTFILE'
  },

  'pcx' => {
    'ext'        => 'pcx',
    'mime'    => 'application/pcx',
    'desc'    => 'Garmin PCX5',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o pcx -F OUTFILE'
  },

  'gpsutil' => {
    'ext'        => 'gpu',
    'mime'    => 'application/gpsutil',
    'desc'    => 'gpsutil',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsutil -F OUTFILE'
  },

  'kml' => {
    'ext'        => 'kml',
    'mime'    => 'application/kml',
    'desc'    => 'KML (Google Earth)',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o kml -F OUTFILE'
  },

  'tiger' => {
    'ext'        => 'tgr',
    'mime'    => 'application/x-tiger',
    'desc'    => 'U.S. Census Bureau Tiger Mapping Service Data',
    'templatePre' =>  "#tms-marker\n",
    'templateWP' => "<%out.londatapad5%>,<%out.latdatapad5%>:redpin:<%wp.name%> by <%wp.creator%>, <%wp.type%> (<%wp.difficulty%>/<%wp.terrain%>)\n"
  },

  'xmap' => {
    'ext'        => 'tgr',
    'mime'    => 'application/xmap',
    'desc'    => 'Delorme Topo USA4/XMap Conduit',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o xmap -F OUTFILE'
  },

  'dna' => {
    'ext'        => 'dna',
    'mime'    => 'application/xmap',
    'desc'    => 'Navitrak DNA marker',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },

  'psp' => {
    'ext'        => 'psp',
    'mime'    => 'application/psp',
    'desc'    => 'Microsoft PocketStreets 2002 Pushpin',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o psp -F OUTFILE'
  },

  'cetus' => {
    'ext'        => 'cet',
    'mime'    => 'application/cetus',
    'desc'    => 'Cetus for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o cetus -F OUTFILE'
  },

  'gpspilot' => {
    'ext'        => 'gps',
    'mime'    => 'application/gpspilot',
    'desc'    => 'GPSPilot for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },

  'magnav' => {
    'ext'        => 'mgv',
    'mime'    => 'application/magnav',
    'desc'    => 'Magellan NAV Companion for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o magnav -F OUTFILE'
  },

  'mxf' => {
    'ext'        => 'mxf',
    'mime'    => 'application/mxf',
    'desc'    => 'MapTech Exchange',
    'templatePre' => '',
    'templateWP' => "<%out.latdatapad5%>, <%out.londatapad5%>, \"<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)\", \"<%out.wid%>\", \"<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)\", ff0000, 47\n"
  },

  'holux' => {
    'ext'        => 'wpo',
    'mime'    => 'application/holux',
    'desc'    => 'Holux gm-100 ',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o holux -F OUTFILE'
  },

  # Tested by efnord @ EFnet.. Thanks!
  'ozi' => {
    'ext'        => 'wpt',
    'mime'    => 'application/x-ozi-wpt',
    'desc'    => 'OziExplorer',
    'templatePre' => "OziExplorer Waypoint File Version 1.1\n" +
      "WGS 84\n" +
      "Reserved 2\n" +
      "Reserved 3\n",
    'templateWP' => "<%out.counter%>,<%out.wid%>,<%out.latdatapad6%>,<%out.londatapad6%>,37761.29167,0,1,3,0,65535,<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>),0,0,0,-777,6,0,17\n"
  },

  'tpg' => {
    'ext'        => 'tpg',
    'mime'    => 'application/tpg',
    'desc'    => 'National Geographic Topo',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tpg -F OUTFILE'
  },

  'tmpro' => {
    'ext'        => 'tmp',
    'mime'    => 'application/tmpro',
    'desc'    => 'TopoMapPro Places',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tmpro -F OUTFILE'
  },

  'gpsdrive' => {
    'ext'        => 'sav',
    'mime'    => 'application/gpsdrive',
    'desc'    => 'GpsDrive',
    'templatePre' => '',
    'templateWP' => "<%out.wid%> <%out.latdatapad5%> <%out.londatapad5%> Geocache\n"
  },

  'cachemate' => {
    'ext'        => 'pdb',
    'mime'    => 'application/cachemate',
    'required' => 'cmconvert',
    'desc'    => 'CacheMate for PalmOS',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'cmconvert -o OUTFILE INFILE'
  },

  'delorme' => {
    'ext'          => 'txt',
    'mime'         => 'application/delorme',
    'desc'         => 'DeLorme TXT import datafile',
    'templatePre'  => "BEGIN SYMBOL\n",
    'templateWP'   => "<%out.latdatapad6%>,<%out.londatapad6%>," +
      "<%out.id%>\{URL=<%wp.url%>\},<%wp.type%>\n",
    'templatePost' => "END",
  },

  'delorme-nourl' => {
    'ext'          => 'txt',
    'mime'         => 'application/delorme',
    'desc'         => 'DeLorme TXT import datafile without URL',
    'templatePre'  => "BEGIN SYMBOL\n",
    'templateWP'   => "<%out.latdatapad6%>,<%out.londatapad6%>," +
      "<%out.id%>,<%wp.type%>\n",
    'templatePost' => "END",
  },

  # contributed by regengott.nass
  'sms' => {
    'ext'         => 'sms',
    'mime'        => 'text/plain',
    'desc'        => '(SMS) Shorten relevant infos for SMS info',
    'spacer'      => "",
    'templatePre' => "",
    'templateWP'  => "<%wpText.name%>,<%out.wid%>,<%wpText.creator%>," +
      "D<%wp.difficulty%>,T<%wp.terrain%>,<%out.relativedistance%>,<%wp.latwritten%>,<%wp.lonwritten%>," +
      "<%wp.type%>,<%wp.size%>\n"
  },

  # contributed by Steve8x8: table, "tab" extended
  'list'    => {
    'ext'        => 'lst',
    'mime'    => 'text/plain',
    'desc'    =>     'whitespace delimited, detailed table',
    'templatePre' => "",
    'templateWP'    => "<%out.id%>\t" +
      "<%out.latdatapad5%> <%out.londatapad5%> " +
      "<%out.cdate%> " +
      "<%wp.difficulty%>/<%wp.terrain%><%out.warnArchiv%><%out.warnAvail%>\t" +
      "<%wp.type%>\t" +
      "<%out.relativedistancekm%>\t" +
      "<%out.size%>\t" + # testing only
      "\"<%wp.name%>\" by <%wp.creator%>\n"
  },

  'qlist'    => {
    'ext'        => 'qlst',
    'mime'    => 'text/plain',
    'desc'    =>     'search results table',
    'templatePre' => "",
    'templateWP'    => "<%out.id%>\t" +
      "0 0 " +
      "<%out.cdate%> " +
      "<%wp.difficulty%>/<%wp.terrain%><%out.warnArchiv%><%out.warnAvail%>\t" +
      "<%wp.type%>\t" +
      "<%out.relativedistancekm%>=" +
      "<%out.relativeazimuth%>\t" +
      "<%out.size%>\t" + # testing only
      "\"<%wp.name%>\" by <%wp.creator%>\n"
  },

  # myfinds (Steve8x8) - use as follows:
  # geotoad -x myfindgpx -o myfinds.gpx -z -q user $USERNAME
  'myfindgpx'    => {
    'ext'        => 'gpx',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML (my finds)',
    'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
      "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\n" +
      "<name>My Finds Pocket Query</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<email>geotoad@googlegroups.com</email>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'    => "<wpt lat=\"<%out.latdatapad5%>\" lon=\"<%out.londatapad5%>\">\n" +
      "  <time><%out.cdate%>T08:00:00Z</time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.fulltype%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <url>http://www.geocaching.com/seek/cache_details.aspx?guid=<%out.guid%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym>Geocache Found</sym>\n" +
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
    'templatePost'    => "</gpx>\n"
  },

  'yourfindgpx'    => {
    'ext'        => 'gpx',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML (user finds)',
    'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
      "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\n" +
      "<name>My Finds Pocket Query</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<email>geotoad@googlegroups.com</email>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n" +
      "<keywords>cache, geocache, groundspeak, geotoad</keywords>\n",
    'templateWP'    => "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.cdate%>T08:00:00Z</time>\n" +
      "  <name><%outEntity.id%></name>\n" +
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.fulltype%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <url>http://www.geocaching.com/seek/cache_details.aspx?guid=<%out.guid%></url>\n" +
      "  <urlname><%wpEntity.name%></urlname>\n" +
      "  <sym>Geocache Found</sym>\n" +
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
    'templatePost'    => "</gpx>\n"
  },

  'myfindlist'    => {
    'ext'        => 'lst',
    'mime'    => 'text/plain',
    'desc'    =>     'whitespace delimited, detailed table (my finds)',
    'templatePre' => "",
    'templateWP'    => "<%out.wid%>\t" +
      "<%out.latdatapad5%> <%out.londatapad5%> " +
      "<%wp.type%>\t" +
      "<%out.adate%> " +
      "\n"
  },

  # mygeocachelist (law.skynet) - use as follows:
  # geotoad -x gclist -o geocache_list.txt -z -q user $USERNAME
  'gclist'    => {
    'ext'     => 'txt',
    'mime'    => 'text/plain',
    'desc'    =>     'Geocache visits text file for Garmin devices',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>,<%out.adate%>T08:00Z,Found it,\"\"\n"
  },

  # mygeocachevisits (law.skynet) - use as follows:
  # geotoad -x gcvisits -o geocache_visits.txt -z -q user $USERNAME
  'gcvisits' => {
    'ext'        => 'txt',
    'mime'    => 'text/plain',
    'required' => 'iconv',
    'desc'    => 'Geocache visits Unicode file for Garmin devices',
    'filter_src'    => 'gclist',
    'filter_exec'    => 'iconv -f US-ASCII -t UCS-2LE INFILE > OUTFILE'
  },

  # map wp to guid
  'wp2guid' => {
    'ext'     => 'w2g',
    'mime'    => 'text/plain',
    'desc'    => 'map wp to guid',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>\t<%out.guid%>\n"
  },

}
