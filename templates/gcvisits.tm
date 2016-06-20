template = {

  # mygeocachelist (law.skynet) - use as follows:
  # geotoad -x gclist -o geocache_list.txt -z --includeArchived -q user $USERNAME
  'gclist'    => {
    'ext'     => 'txt',
    'mime'    => 'text/plain',
    'desc'    => 'Garmin geocache_visits (text)',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>,<%out.adate%>T08:00Z,Found it,\"\"\n"
  },

  # geotoad -x gcvisits -o geocache_visits.txt -z --includeArchived -q user $USERNAME
  'gcvisits'  => {
    'ext'     => 'txt',
    'mime'    => 'text/plain',
    'required'=> 'iconv',
    'desc'    => 'Garmin geocache_visits (Unicode)',
    'filter_src'  => 'gclist',
    'filter_exec' => 'iconv -f US-ASCII -t UCS-2LE INFILE > OUTFILE'
  },

  # extension "for friends" as suggested by Christian Meyer aka MeyerCG
  'yourgclist'    => {
    'ext'     => 'txt',
    'mime'    => 'text/plain',
    'desc'    => 'Garmin your_geocache_visits (text)',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>,<%out.mdate%>T08:00Z,Found it,\"\"\n"
  },

  'yourgcvisits'  => {
    'ext'     => 'txt',
    'mime'    => 'text/plain',
    'required'=> 'iconv',
    'desc'    => 'Garmin your_geocache_visits (Unicode)',
    'filter_src'  => 'yourgclist',
    'filter_exec' => 'iconv -f US-ASCII -t UCS-2LE INFILE > OUTFILE'
  },

}
