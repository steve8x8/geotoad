# seldom used table-type formats
#
template = {

  'gpsdrive' => {
    'ext'  => 'sav',
    'desc' => 'GpsDrive',
    'templatePre' => '',
    'templateWP'  =>
      "<%out.wid%> <%out.latdatapad5%> <%out.londatapad5%> Geocache\n"
  },

  'mxf' => {
    'ext'  => 'mxf',
    'desc' => 'MapTech Exchange',
    'templatePre' => '',
    'templateWP'  =>
      "<%out.latdatapad5%>, <%out.londatapad5%>, \"<%wp.name%> by <%wp.creator%>" +
      " (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)\", \"<%out.wid%>\"," +
      " \"<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)\", ff0000, 47\n"
  },

  # Tested by efnord @ EFnet.. Thanks!
  'ozi' => {
    'ext'  => 'wpt',
    'desc' => 'OziExplorer',
    'templatePre' =>
      "OziExplorer Waypoint File Version 1.1\n" +
      "WGS 84\n" +
      "Reserved 2\n" +
      "Reserved 3\n",
    'templateWP'  =>
      "<%out.counter%>,<%out.wid%>,<%out.latdatapad6%>,<%out.londatapad6%>," +
      "37761.29167,0,1,3,0,65535," +
      "<%wp.name%> by <%wp.creator%>" +
      " (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)," +
      "0,0,0,-777,6,0,17\n"
  },

  'tiger' => {
    'ext'  => 'tgr',
    'desc' => 'U.S. Census Bureau Tiger Mapping Service Data',
    'templatePre' =>
      "#tms-marker\n",
    'templateWP'  =>
      "<%out.londatapad5%>,<%out.latdatapad5%>:redpin:<%wp.name%> by <%wp.creator%>, <%wp.type%>" +
      " (<%wp.difficulty%>/<%wp.terrain%>)\n"
  },

}
