template = {

  # Templates for Garmin nuvi road navigation devices. Use 'gpx-wpts' to add waypoints.
  # Thanks to Kevin Bulgrien and the author(s) of the GPX_by_Cache_Type.gsk GSAK macro.
  # Note: points will show up under "Custom POIs"!
  # Tested with Garmin nuvi 255T which doesn't allow multiple entries.
  # Further improved following
  # http://home.comcast.net/~ghayman3/garmin.gps/pagepoi.05.htm
  # http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html
  # http://geocachingunterland.wordpress.com/2009/04/20/babylonisches-sprachgenie-teil-2-ersatz-fur-den-garmin-poi-loader/
  # http://bigfraud.org/mac/MacGarminTools/gpx2gpi.html
  # Still missing: radial alerts (need TourGuide features? not in gpsbabel)
  #
  # You may consider using the gpx-wpts (wgpx) output for additional waypoints (parking etc.)!

  'gpx-nuvi' => {
    'ext'  => 'ngpx',
    'mime' => 'text/ascii',
    'desc' => 'GPX for Nuvi, without AddWpts',
    'templatePre'  =>
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
# left out intentionally: there's no groundspeak content
#        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
        " http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensions/v3/GpxExtensionsv3.xsd" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
       " xmlns:gpxx=\"http://www.garmin.com/xmlschemas/GpxExtensions/v3\"" +
      ">\n" +
      "<name>" + Time.new.gmtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".000Z</time>\n",
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.XMLDate%></time>\n" +
      # title line, 1st line in POI list, max 24 chars shown
      "  <name><%outEntity.wid%>:<%out.nuvi%></name>\n" +
      "  <cmt></cmt>\n" +
      # last line in display if cmt is empty
      "  <desc><%wpEntity.name%><%out.warnArchiv%><%out.warnAvail%> by <%wpEntity.creator%>," +
        " <%wp.fulltype%> (<%wp.size%>/<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <sym>Geocache</sym>\n" +
# SAXCount chokes on <extensions> but without there's no text in GPI
      "  <extensions>\n" +
      "    <gpxx:WaypointExtension>\n" +
      # do NOT set proximity here as it cannot be overwritten by POIloader/gpsbabel!
      #"      <gpxx:Proximity>250</gpxx:Proximity>\n" +
      "      <gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>\n" +
      # gpsbabel doesn't know (but complains) about categories
      #"      <gpxx:Categories>\n" +
      #"        <gpxx:Category><%wp.fulltype%></gpxx:Category>\n" +
      #"      </gpxx:Categories>\n" +
      "      <gpxx:Address>\n" +
               # 2nd line in POI list, max 24 chars shown
      "        <gpxx:StreetAddress><%wpEntity.name%></gpxx:StreetAddress>\n" +
      "        <gpxx:City><%wp.fulltype%> - <%wp.size%> -</gpxx:City>\n" +
      "        <gpxx:State>D <%wp.difficulty%> - T <%wp.terrain%></gpxx:State>\n" +
      "        <gpxx:PostalCode>by <%wpEntity.creator%> (<%out.cdate%>) -</gpxx:PostalCode>\n" +
      "      </gpxx:Address>\n" +
             # nuvi 255 only accepts a single phone number, doesn't show the category
      "      <gpxx:PhoneNumber Category=\"Details\">\n" +
        # only one line is shown first (press "more"...)
        # there are rumours that nuvis accept <b>...</b> <u>...</u>
        "**Loca: <%wp.latwritten%> / <%wp.lonwritten%>\n" +
        "**Last: <%wp.last_find_type%>, <%wp.last_find_days%> days ago\n" +
        "**Stat: <%wp.logcounts%>\n" +
        "**Attr: <%out.premiumOnly%><%out.warnArchiv%><%out.warnAvail%> <%out.txtAttrs%>\n" +
        "**Trck: <%out.trackables%>\n" +
        "**Hint: <%outEntity.hintdecrypt%>\n" +
        "**Desc: <%wpTextEntity.shortdesc%>\n" +
        "**Long:\n<%wpTextEntity.longdesc%>\n" +
        "**Logs:\n<%outTextEntity.textlogs%>\n" +
        #"**Wpts: <%outTextEntity.shortWpts%>\n" +
      "      </gpxx:PhoneNumber>\n" +
      "    </gpxx:WaypointExtension>\n" +
      "  </extensions>\n" +
      "</wpt>\n",
    'templatePost' =>
      "</gpx>\n"
  },

  'poi-nuvi' => {
    'ext'         => 'gpi',
    'mime'        => 'application/poiloader',
    'desc'        => 'POI for Nuvi',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx-nuvi',
    # hide: don't show a symbol
    # proximity: set alert at given distance (forces alerts=1)
    # sleep: make sure no 2 files have same timestamp
    #'filter_exec' => 'gpsbabel -i gpx -o garmin_gpi,category="Geocaches",hide,proximity=250m,sleep=2 -f INFILE -F OUTFILE'
    'filter_exec' => 'gpsbabel -i gpx -o garmin_gpi,category="Geocaches",proximity=250m,sleep=2 -f INFILE -F OUTFILE'
  },

}
