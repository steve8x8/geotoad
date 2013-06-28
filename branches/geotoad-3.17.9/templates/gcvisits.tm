template = {
  # mygeocachelist (law.skynet) - use as follows:
  # geotoad -x gclist -o geocache_list.txt -z -q user $USERNAME
  'gclist'    => {
    'ext'     => 'txt',
    'mime'    => 'text/plain',
    'desc'    =>     'Geocache visits text file for Garmin devices',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>,<%out.adate%>T08:00Z,Found it,\"\"\n"
  },
  # geotoad -x gcvisits -o geocache_visits.txt -z -q user $USERNAME
  'gcvisits' => {
    'ext'        => 'txt',
    'mime'    => 'text/plain',
    'required' => 'iconv',
    'desc'    => 'Geocache visits Unicode file for Garmin devices',
    'filter_src'    => 'gclist',
    'filter_exec'    => 'iconv -f US-ASCII -t UCS-2LE INFILE > OUTFILE'
  },
}
