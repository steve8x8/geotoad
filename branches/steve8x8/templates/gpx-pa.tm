template = {
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
}
