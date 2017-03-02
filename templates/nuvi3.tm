template = {

  # Templates for Garmin nuvi 3xx road navigation devices which lack some features.
  #
  # Thanks to Kevin Bulgrien and the author(s) of the GPX_by_Cache_Type.gsk GSAK macro.
  # Further improved following
  #  http://home.comcast.net/~ghayman3/garmin.gps/pagepoi.05.htm
  #  http://www.gpsbabel.org/htmldoc-development/fmt_garmin_gpi.html
  #  http://geocachingunterland.wordpress.com/2009/04/20/babylonisches-sprachgenie-teil-2-ersatz-fur-den-garmin-poi-loader/
  #  http://bigfraud.org/mac/MacGarminTools/gpx2gpi.html
  #  http://www.naviboard.de/archive/index.php/t-49399.html
  #
  # Still missing: radial alerts (need TourGuide features? not in gpsbabel)
  # 2017: GPX/1/1 for extensions; remove some elements to make "SAXCount -v=always -n -s -f $file" happy

  'gpx-nuvi3' => {
    'ext'  => 'ngpx',
    'desc' => 'GPX for Nuvi 3xx, without AddWpts',
    'templatePre'  =>
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
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <time><%out.ctime%></time>\n" +
      "  <name><%outEntity.wid%>:<%out.nuvi%></name>\n" +
      "  <cmt></cmt>\n" +
      "  <sym>Geocache</sym>\n" +
      "  <extensions>\n" +
      "    <gpxx:WaypointExtension>\n" +
      "      <gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>\n" +
      "      <gpxx:PhoneNumber Category=\"Email\">\n" +
        "<%wpEntity.name%><%out.warnArchiv%><%out.warnAvail%> by <%wpEntity.creator%>, " +
        "<%wp.fulltype%> (<%wp.size%>/<%wp.difficulty%>/<%wp.terrain%>)" +
      "    </gpxx:PhoneNumber>\n" +
# need feedback: does this work at all?
      "      <gpxx:PhoneNumber Category=\"Details\">\n" +
        "...\n" +
        "**Loca:  <%wp.latwritten%> / <%wp.lonwritten%>\n" +
        "**Last:  <%wp.last_find_type%>, <%wp.last_find_days%> days ago\n" +
        "**Stat:  <%wp.logcounts%>\n" +
        "**Attr:\n<%out.premiumOnly%><%out.warnArchiv%><%out.warnAvail%> <%out.txtAttrs%>\n" +
        "**Trck:  <%out.trackables%>\n" +
        "**Hint:  <%outEntity.hintdecrypt%>\n" +
        "**Desc:\n<%wpTextEntity.shortdesc%>\n" +
        "**Long:\n<%wpTextEntity.longdesc%>\n" +
        "**Wpts: <%outTextEntity.shortWpts%>\n" +
        "**Logs:\n<%outTextEntity.textlogs%>\n" +
      "      </gpxx:PhoneNumber>\n" +
      "    </gpxx:WaypointExtension>\n" +
      "  </extensions>\n" +
      "</wpt>\n",
    'templatePost' =>
      "</gpx>\n"
  },

  'poi-nuvi3' => {
    'ext'         => 'gpi',
    'desc'        => 'POI for Nuvi, pure ASCII',
    'required'    => 'gpsbabel:iconv',
    'filter_src'  => 'gpx-nuvi3',
    #use the following if you prefer UTF-8
    #'filter_exec' => 'gpsbabel -i gpx -o garmin_gpi,category="Geocaches",bitmap=STYLEFILE,alerts=1,unique=0,proximity=250m,sleep=2 -f INFILE -F OUTFILE'
    'filter_exec' => 'cat INFILE | tr \'«‹›»\' \'*\' | iconv -f UTF8 -t ASCII//TRANSLIT -c | ' +
                      'gpsbabel -i gpx -o garmin_gpi,category="Geocaches",bitmap=STYLEFILE,alerts=1,unique=0,proximity=250m,sleep=2 -f - -F OUTFILE',
    # "G" geocaching symbol, created in xpaint
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
