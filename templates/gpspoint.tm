template = {

  # revised using http://mpickering.homeip.net/software/gpspoint_to_gpx.py
  # see also http://mirror.rosalab.ru/rosa/rosa2012.1/repository/SRPMS/contrib/release/gpspoint-2.030521-7.src.rpm
  'gpspoint' => {
    'ext'          => 'gpd',
    'desc'         => 'GpsPoint data file',
    'templatePre'  =>
      "GPSPOINT DATA FILE\ntype=\"fileinfo\"  version=\"1.00\"\n" +
      "type=\"programinfo\" program=\"geotoad\" version=\"<%outEntity.version%>\"\n" +
      "type=\"waypointlist\"\n",
    'templateWP'   =>
      "type=\"waypoint\" " +
      "latitude=\"<%out.latdatapad5%>\" longitude=\"<%out.londatapad5%>\" " +
      "name=\"<%out.id%>\" comment=\"<%wp.name%> (Geocache:<%wp.type%>/<%wp.size%>/D<%wp.difficulty%>/T<%wp.terrain%>)\" " +
      "symbol=\"flag\"  display_option=\"symbol+name\"\n",
    'templatePost' =>
      "type=\"waypointlistend\"\n",
  },

  # use gpsbabel to create gpspoint file from gpx
  'gpspoint2' => {
    'ext'          => 'gpd',
    'desc'         => 'GpsPoint data file (by gpsbabel)',
    'required'     => 'gpsbabel',
    'filter_src'   => 'gpx',
    'filter_exec'  => 'gpsbabel -i gpx -f INFILE -o xcsv,style=STYLEFILE -F OUTFILE',
    'filter_style' => "#STYLEFILE: (inpired by Mike Pickering, 6/19/2005)\n" +
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

}
