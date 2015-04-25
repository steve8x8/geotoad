# collection of "deprecated" gpsbabel formats
# see gpsbabel/deprecated/README, Robert Lipe 2013-08-20

template = {

  'cetus' => {
    'ext'        => 'cet',
    'mime'    => 'application/cetus',
    'desc'    => 'Cetus for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o cetus -F OUTFILE'
  },

  'gpspilot' => {
    'ext'        => 'gps',
    'mime'    => 'application/gpspilot',
    'desc'    => 'GPSPilot for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },

  'magnav' => {
    'ext'        => 'mgv',
    'mime'    => 'application/magnav',
    'desc'    => 'Magellan NAV Companion for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o magnav -F OUTFILE'
  },

  'psp' => {
    'ext'        => 'psp',
    'mime'    => 'application/psp',
    'desc'    => 'Microsoft PocketStreets 2002 Pushpin',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o psp -F OUTFILE'
  },

}
