# collection of output templates using a converter
#
template = {

  'cachemate' => {
    'ext'         => 'pdb',
    'desc'        => 'CacheMate for PalmOS',
    'required'    => 'cmconvert',
    'filter_src'  => 'gpx',
    'filter_exec' => 'cmconvert -o OUTFILE INFILE'
  },

  'dna' => {
    'ext'         => 'dna',
    'desc'        => 'Navitrak DNA marker',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
  },

  'gpsman' => {
    'ext'         => 'gpm',
    'desc'        => 'GPSman datafile',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o gpsman -F OUTFILE'
  },

  'gpsutil' => {
    'ext'         => 'gpu',
    'desc'        => 'gpsutil',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o gpsutil -F OUTFILE'
  },

  'holux' => {
    'ext'         => 'wpo',
    'desc'        => 'Holux gm-100 ',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o holux -F OUTFILE'
  },

  'mapsend' => {
    'ext'         => 'mps',
    'desc'        => 'Magellan MapSend software',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec'  => 'gpsbabel -i gpx  -f INFILE -o mapsend -F OUTFILE'
  },

  'pcx' => {
    'ext'         => 'pcx',
    'desc'        => 'Garmin PCX5',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o pcx -F OUTFILE'
  },

  'tmpro' => {
    'ext'         => 'tmp',
    'desc'        => 'TopoMapPro Places',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o tmpro -F OUTFILE'
  },

  'tpg' => {
    'ext'         => 'tpg',
    'desc'        => 'National Geographic Topo',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o tpg -F OUTFILE'
  },

  'xmap' => {
    'ext'         => 'xmp',
    'desc'        => 'DeLorme Topo USA4/XMap Conduit',
    'required'    => 'gpsbabel',
    'filter_src'  => 'gpx',
    'filter_exec' => 'gpsbabel -i gpx -f INFILE -o xmap -F OUTFILE'
  },

}
