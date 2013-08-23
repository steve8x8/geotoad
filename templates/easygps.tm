template = {
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
}
