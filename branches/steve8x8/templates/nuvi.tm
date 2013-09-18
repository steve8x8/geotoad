template = {
  # Templates for Garmin nuvi road navigation devices. Use 'gpx-wpts' to add waypoints.
  # Thanks to Kevin Bulgrien and the author(s) of the GPX_by_Cache_Type.gsk GSAK macro.
  # Note: points will show up under "Custom POIs"!
  # Tested with Garmin nuvi 255T which doesn't allow multiple entries.

  'gpx-nuvi'    => {
    'ext'     => 'gpxn',
    'mime'    => 'text/ascii',
    'desc'    => 'GPX Geocaching XML for Nuvi, without Additional Waypoints',
    'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n" +
      "<gpx" +
        #" xmlns=\"http://www.topografix.com/GPX/1/1\"" +
        #" xmlns:gpxx = \"http://www.garmin.com/xmlschemas/GpxExtensions/v3\"" +
        #" creator=\"GeoToad for nuvi thru POIloader or GPSbabel\"" +
        #" version=\"1.1\"" +
        #" xmlns:xsi = \"http://www.w3.org/2001/XMLSchema-instance\"" +
        #" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1" +
        #  " http://www.topografix.com/GPX/1/1/gpx.xsd" +
        #  " http://www.garmin.com/xmlschemas/GpxExtensions/v3" +
        #  " http://www8.garmin.com/xmlschemas/GpxExtensions/v3/GpxExtensionsv3.xsd" +
        #  "\"" +
        ">\n" +
      "<name>" + Time.new.gmtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<author>GeoToad <%outEntity.version%></author>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + "</time>\n",
    'templateWP'    => "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.XMLDate%></time>\n" +
      # title line, 1st line in POI list, max 24 chars shown
      "  <name><%outEntity.id%>/<%out.type3%>/<%wp.difficulty%>/<%wp.terrain%></name>\n" +
      "  <cmt></cmt>\n" +
      # last line in display if cmt is empty
      "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.fulltype%> (<%wp.size%>/<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <sym>Geocache</sym>\n" +
      "  <extensions>\n" +
      "    <gpxx:WaypointExtension>\n" +
      "      <gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>\n" +
             # gpsbabel doesn't know (but complains) about categories
      "      <gpxx:Categories>\n" +
      "        <gpxx:Category><%wp.fulltype%></gpxx:Category>\n" +
      "      </gpxx:Categories>\n" +
      "      <gpxx:Address>\n" +
               # 2nd line in POI list, max 24 chars shown
      "        <gpxx:StreetAddress><%wpEntity.name%></gpxx:StreetAddress>\n" +
      "        <gpxx:PostalCode>by <%wpEntity.creator%> (<%out.cdate%>) -</gpxx:PostalCode>\n" +
      "        <gpxx:City><%wp.fulltype%> - <%wp.size%> -</gpxx:City>\n" +
      "        <gpxx:State>D <%wp.difficulty%> - T <%wp.terrain%></gpxx:State>\n" +
      "      </gpxx:Address>\n" +
             # nuvi 255 only accepts a single phone number, doesn't show the category
      "      <gpxx:PhoneNumber Category=\"Details\">\n" +
        # only one line is shown first (press "more"...)
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
    'templatePost'    => "</gpx>\n"
  },

  'poi-nuvi' => {
    'ext'        => 'gpi',
    'mime'       => 'application/poiloader',
    'desc'       => 'POI for Nuvi',
    'required'   => 'gpsbabel',
    'filter_src' => 'gpx-nuvi',
    # hide: don't show a symbol; sleep: make sure no 2 files have same timestamp
    'filter_exec' => 'gpsbabel -i gpx -o garmin_gpi,category="Geocache",hide,sleep=2 -f INFILE -F OUTFILE'
  },

}
