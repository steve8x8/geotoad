template = {

  # mygeocachelist (law.skynet) - use as follows:
  # geotoad -x gclist -o geocache_list.txt -z --includeArchived -q user $USERNAME
  'gclist'    => {
    'ext'     => 'txt',
    'desc'    => 'Garmin geocache_visits (text)',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>,<%out.atime_hm%>,Found it,\"\"\n"
  },

  # geotoad -x gcvisits -o geocache_visits.txt -z --includeArchived -q user $USERNAME
  'gcvisits'  => {
    'ext'     => 'txt',
    'required'=> 'iconv',
    'desc'    => 'Garmin geocache_visits (Unicode)',
    'filter_src'  => 'gclist',
    'filter_exec' => 'iconv -f US-ASCII -t UCS-2LE INFILE > OUTFILE'
  },

  # extension "for friends" as suggested by Christian Meyer aka MeyerCG
  'yourgclist'    => {
    'ext'     => 'txt',
    'desc'    => 'Garmin your_geocache_visits (text)',
    'templatePre' => "",
    'templateWP'  => "<%out.wid%>,<%out.mtime_hm%>,Found it,\"\"\n"
  },

  'yourgcvisits'  => {
    'ext'     => 'txt',
    'required'=> 'iconv',
    'desc'    => 'Garmin your_geocache_visits (Unicode)',
    'filter_src'  => 'yourgclist',
    'filter_exec' => 'iconv -f US-ASCII -t UCS-2LE INFILE > OUTFILE'
  },

}
