# colection of output templates using a converter
#
template = {
  'cachemate' => {
    'ext'        => 'pdb',
    'mime'    => 'application/cachemate',
    'desc'    => 'CacheMate for PalmOS',
    'required' => 'cmconvert',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'cmconvert -o OUTFILE INFILE'
  },
  'cetus' => {
    'ext'        => 'cet',
    'mime'    => 'application/cetus',
    'desc'    => 'Cetus for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o cetus -F OUTFILE'
  },
  'dna' => {
    'ext'        => 'dna',
    'mime'    => 'application/xmap',
    'desc'    => 'Navitrak DNA marker',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },
  'gpsman' => {
    'ext'        => 'gpm',
    'mime'    => 'application/gpsman',
    'desc'    => 'GPSman datafile',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsman -F OUTFILE'
  },
  'gpspilot' => {
    'ext'        => 'gps',
    'mime'    => 'application/gpspilot',
    'desc'    => 'GPSPilot for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },
  'gpsutil' => {
    'ext'        => 'gpu',
    'mime'    => 'application/gpsutil',
    'desc'    => 'gpsutil',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsutil -F OUTFILE'
  },
  'holux' => {
    'ext'        => 'wpo',
    'mime'    => 'application/holux',
    'desc'    => 'Holux gm-100 ',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o holux -F OUTFILE'
  },
  'magnav' => {
    'ext'        => 'mgv',
    'mime'    => 'application/magnav',
    'desc'    => 'Magellan NAV Companion for PalmOS',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o magnav -F OUTFILE'
  },
  'mapsend' => {
    'ext'        => 'mps',
    'mime'    => 'application/mapsend',
    'desc'    => 'Magellan MapSend software',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx  -f INFILE -o mapsend -F OUTFILE'
  },
  'pcx' => {
    'ext'        => 'pcx',
    'mime'    => 'application/pcx',
    'desc'    => 'Garmin PCX5',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o pcx -F OUTFILE'
  },
  'psp' => {
    'ext'        => 'psp',
    'mime'    => 'application/psp',
    'desc'    => 'Microsoft PocketStreets 2002 Pushpin',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o psp -F OUTFILE'
  },
  'tmpro' => {
    'ext'        => 'tmp',
    'mime'    => 'application/tmpro',
    'desc'    => 'TopoMapPro Places',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tmpro -F OUTFILE'
  },
  'tpg' => {
    'ext'        => 'tpg',
    'mime'    => 'application/tpg',
    'desc'    => 'National Geographic Topo',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tpg -F OUTFILE'
  },
  'xmap' => {
    'ext'        => 'tgr',
    'mime'    => 'application/xmap',
    'desc'    => 'Delorme Topo USA4/XMap Conduit',
    'required' => 'gpsbabel',
    'filter_src'    => 'gpx',
    'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o xmap -F OUTFILE'
  },
}
