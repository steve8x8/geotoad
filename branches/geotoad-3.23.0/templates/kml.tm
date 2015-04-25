template = {

  'kml' => {
    'ext'        => 'kml',
    'mime'    => 'application/kml',
    'desc'    => 'KML (Google Earth)',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o kml -F OUTFILE'
  },

}
