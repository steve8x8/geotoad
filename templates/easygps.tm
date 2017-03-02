template = {

  # trying to mimic Groundspeak's LOC output as much as possible
  # following issue 298 report, 2014-02-07:

  #<?xml version="1.0" encoding="UTF-8"?>(cr)
  #<loc version="1.0" src="Groundspeak">(cr)
  #<waypoint>(cr)
  #	<name id="GC2AD16"><![CDATA[Adslev skoven - over broen ved Pinds Mølle by TIDOKU]]>(cr)
  #</name>(cr)
  #<coord lat="56.108083" lon="10.010167"/>(cr)
  #<type>Geocache</type>(cr)
  #<link text="Cache Details">http://www.geocaching.com/seek/cache_details.aspx?wp=GC2AD16</link>(cr)
  #</waypoint></loc>(no crlf!)

  'easygps' => {
    'ext'  => 'loc',
    'desc' => 'Geocaching.com .loc XML file',
    'templatePre' =>
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
      "<loc version=\"1.0\" src=\"GeoToad <%outEntity.version%>\">",
    # line feed in front of waypoints!
    'templateWP'  =>
      "\n<waypoint>\n" + 
      "\t<name id=\"<%out.id%>\"><![CDATA[<%wp.name%> by <%wp.creator%>]]>\n" +
      "</name>\n" +
      "<coord lat=\"<%out.latdatapad6%>\" lon=\"<%out.londatapad6%>\"/>\n" +
      "<type>Geocache</type>\n" +
      "<link text=\"Cache Details\"><%wp.url%></link>\n" +
      "</waypoint>",
    'templatePost' =>
      "</loc>",
    # there's no trailing LF in the reference file
  },

}
