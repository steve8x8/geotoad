template = {

  # Templates for Garmin nuvi road navigation devices. Use 'gpx-wpts' to add waypoints.
  #
  # Thanks to Kevin Bulgrien and the author(s) of the GPX_by_Cache_Type.gsk GSAK macro.
  # *Tested with Garmin nuvi 255T which doesn't allow multiple phone entries.
  # Further improved following
  #  http://home.comcast.net/~ghayman3/garmin.gps/pagepoi.05.htm
  #  http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html
  #  http://geocachingunterland.wordpress.com/2009/04/20/babylonisches-sprachgenie-teil-2-ersatz-fur-den-garmin-poi-loader/
  #  http://bigfraud.org/mac/MacGarminTools/gpx2gpi.html
  #  http://www.naviboard.de/archive/index.php/t-49399.html
  #
  # Still missing: radial alerts (need TourGuide features? not in gpsbabel)
  # 2017: GPX/1/1 for extensions; remove some elements to make "SAXCount -v=always -n -s -f $file" happy

  'gpx-nuvi' => {
    'ext'  => 'ngpx',
    'desc' => 'GPX for Nuvi, without AddWpts',
    'templatePre'  =>
# encoding should be 'Windows-1252' (if we find out how to write this)
      "<?xml version=\'1.0\' encoding=\'UTF-8\' standalone=\'yes\' ?>\n" +
      "<gpx" +
       " version=\"1.1\" creator=\"GeoToad <%outEntity.version%>\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" +
        " http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensions/v3/GpxExtensionsv3.xsd" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/1\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:gpxx=\"http://www.garmin.com/xmlschemas/GpxExtensions/v3\"" +
      ">\n" +
      "<metadata>\n" +
      "  <name>" + Time.new.localtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "  <desc><%outEntity.title%></desc>\n" +
      "  <time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%SZ")  + "</time>\n" +
      "</metadata>\n",
# *Unicode characters (degree symbol, umlauts, etc.) will be shown as 3-character garbage
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.ctime%></time>\n" +
# *title line, 1st line in POI list, max 24 chars shown
      "  <name><%outEntity.wid%>:<%out.nuvi%></name>\n" +
      "  <cmt></cmt>\n" +
# *last line in display if cmt is empty (UTF-8 works only here! why?)
      "  <desc><%wpEntity.name%><%out.warnArchiv%><%out.warnAvail%> by <%wpEntity.creator%>," +
        " <%wp.fulltype%> (<%wp.size%>/<%wp.difficulty%>/<%wp.terrain%>)</desc>\n" +
      "  <sym>Geocache</sym>\n" +
      "  <extensions>\n" +
      "    <gpxx:WaypointExtension>\n" +
# do NOT set proximity here as it cannot be overwritten by POIloader/gpsbabel!
#      "      <gpxx:Proximity>250</gpxx:Proximity>\n" +
      "      <gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>\n" +
# gpsbabel doesn't know (but complains) about categories
#      "      <gpxx:Categories>\n" +
#      "        <gpxx:Category><%wp.fulltype%></gpxx:Category>\n" +
#      "      </gpxx:Categories>\n" +
      "      <gpxx:Address>\n" +
# *2nd line in POI list, max 24 chars shown
# *1st description line
      "        <gpxx:StreetAddress><%wpEntity.name%></gpxx:StreetAddress>\n" +
# *2nd description line "PostalCode City State" - localization dependent?
      "        <gpxx:City><%wp.fulltype%> - <%out.csize%> -</gpxx:City>\n" +
      "        <gpxx:State>D <%wp.difficulty%> - T <%wp.terrain%></gpxx:State>\n" +
      "        <gpxx:PostalCode>by <%wpEntity.creator%> (<%out.cdate%>) -</gpxx:PostalCode>\n" +
      "      </gpxx:Address>\n" +
# nuvi 255 only accepts a single phone number, doesn't show the category
      "      <gpxx:PhoneNumber Category=\"Details\">\n" +
# there are rumours that nuvis accept <b>...</b> <u>...</u>? (escape properly!)
# does this add a line feed?
        "...\n" +
        "**Loca:  <%wp.latwritten%> / <%wp.lonwritten%>\n" +
        "**Last:  <%wp.last_find_type%>, <%wp.last_find_days%> days ago\n" +
        "**Stat:  <%wp.logcounts%>\n" +
        "**Attr:\n<%out.premiumOnly%><%out.warnArchiv%><%out.warnAvail%> <%out.txtAttrs%>\n" +
        "**Trck:  <%out.trackables%>\n" +
        "**Hint:  <%outEntity.hintdecrypt%>\n" +
        "**Desc:\n<%wpTextEntity.shortdesc%>\n" +
        "**Long:\n<%wpTextEntity.longdesc%>\n" +
        "**Logs:\n<%outTextEntity.textlogs%>\n" +
      "      </gpxx:PhoneNumber>\n" +
      "    </gpxx:WaypointExtension>\n" +
      "  </extensions>\n" +
      "</wpt>\n",
    'templatePost' =>
      "</gpx>\n"
  },

# *nüvi 255 doesn't like UTF-8, best to trim everything down to ASCII. Avoid <>!
  'poi-nuvi' => {
    'ext'         => 'gpi',
    'desc'        => 'POI for Nuvi, pure ASCII',
    'required'    => 'gpsbabel:iconv',
    'filter_src'  => 'gpx-nuvi',
    # hide: don't show a symbol
    # proximity: set alert at given distance (forces alerts=1)
    # sleep: make sure no 2 files have same timestamp
    #use the following if you prefer UTF-8
    #'filter_exec' => 'gpsbabel -i gpx -o garmin_gpi,category="Geocaches",bitmap=STYLEFILE,alerts=1,unique=0,proximity=250m,sleep=2 -f INFILE -F OUTFILE'
    'filter_exec' => 'cat INFILE | tr \'«‹›»\' \'*\' | iconv -f UTF8 -t ASCII//TRANSLIT -c | ' +
                      'gpsbabel -i gpx -o garmin_gpi,category="Geocaches",bitmap=STYLEFILE,alerts=1,unique=0,proximity=250m,sleep=2 -f - -F OUTFILE',
    'filter_style64' => "Qk2yAQAAAAAAAEoAAAAoAAAAEgAAABIAAAABAAgAAAAAAGgBAABtCwAAbQsAAAUAAAAFAAAA/wD/\n" +
                        "AP///wCZmZkAAAAAAMzMzAAAAAAAAAEBAQEBAQEBAAAAAAAAAAAAAAEBAgMDAwMDAwIBAQAAAAAA\n" +
                        "AAABBAMDBAEBAQEEAwMEAQAAAAAAAQQDAgEBAQAAAQEBAgMEAQAAAAABAwIBAQAAAAEDAQEBAgMB\n" +
                        "AAAAAQIDAQEAAAABAgMBAAEBAwIBAAABAwQBAQEBAAEDAgEAAAEEAwEAAAEDAQEDAwIBBAMBAAAA\n" +
                        "AQEDAQAAAQMBAAECAwMDAwQBAQAAAQMBAAABAwEAAAEBBAMDAwMCAQEBAwEAAAEDAQEAAAABAwQB\n" +
                        "AgMDAwIDAQAAAQMEAQAAAQIDAQABAQECAwMBAAABAgMBAQABAwIBAAAAAQEBAQEAAAABAwIBAQED\n" +
                        "AQAAAAEBAgMBAAAAAAEEAwIBAQEAAAEBAQIDBAEAAAAAAAEEAwMEAQEBAQQDAwQBAAAAAAAAAAEB\n" +
                        "AgMDAwMDAwIBAQAAAAAAAAAAAAABAQEBAQEBAQAAAAAAAAA=\n"
  },

}
