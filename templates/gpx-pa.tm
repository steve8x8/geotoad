template = {

  # Modified GPX XML for PathAway, which doesn't support HTML content in gpx files.
  # Since <groundspeak:...> tags are ignored, so we have to include all the necessary information in the <desc> tag
  # Originally contributed by Tris Sethur, Sep 2011
  'gpx-pa' => {
    'ext'  => 'gpx',
    'desc' => 'GPX for PathAway',
    'templatePre'  =>
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
      "<gpx" +
       " version=\"1.0\" creator=\"GeoToad <%outEntity.version%>\"" +
       " xsi:schemaLocation=\"" +
         "http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" +
        " http://www.groundspeak.com/cache/1/0/1 http://www.groundspeak.com/cache/1/0/1/cache.xsd" +
       "\"" +
       " xmlns=\"http://www.topografix.com/GPX/1/0\"" +
       " xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"" +
       " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"" +
       " xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0/1\"" +
      ">\n" +
      "<name>" + Time.new.localtime.strftime("%Y%m%dT%H%M%S") + "</name>\n" +
      "<desc><%outEntity.title%></desc>\n" +
      "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S.000Z")  + "</time>\n",
    'templateWP'   =>
      "<wpt lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\">\n" +
      "  <name>" + '<![CDATA[' + "<%outEntity.id%>" + ']]>' + "</name>\n" +
      "  <desc>" + '<![CDATA[' +
        "<%outEntity.wid%>:<%wpText.name%>\n=== <%wp.type%> (D:<%wp.difficulty%>/T:<%wp.terrain%>/F:<%wp.favfactor%>/S:<%wp.size%>) by <%wpText.creator%>\n" +
        "<%outText.warnArchiv%><%outText.warnAvail%><%outText.txtAttrs%>\n" +
        "<%wpText.shortdesc%>\nDescription: <%wpText.longdesc%>\n" +
        "Hint:<%outText.hint%>" + ']]>' +
        "</desc>\n" +
      "  <sym><%outEntity.cacheSymbol%></sym>\n" +
      "</wpt>\n" +
      "<%out.xmlWpts%>",
    'templatePost' =>
      "</gpx>\n"
  },

}
