# collection of "deprecated" gpsbabel formats
# see gpsbabel/deprecated/README, Robert Lipe 2013-08-20

template = {

  'cetus' => {
    'ext'         => 'cet',
    'desc'        => 'Cetus for PalmOS',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o cetus -F OUTFILE'
  },

  'gpspilot' => {
    'ext'         => 'gps',
    'desc'        => 'GPSPilot for PalmOS',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },

  'magnav' => {
    'ext'         => 'mgv',
    'desc'        => 'Magellan NAV Companion for PalmOS',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o magnav -F OUTFILE'
  },

  'psp' => {
    'ext'         => 'psp',
    'desc'        => 'Microsoft PocketStreets 2002 Pushpin',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o psp -F OUTFILE'
  },

}
