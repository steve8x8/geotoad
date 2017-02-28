template = {

  # derived from "list" template, re-sort by date
  'eventlist' => {
    'ext'         => 'lst',
    'mime'        => 'text/plain',
    'desc'        =>     'Sorted table, whitespace delimited',
    'filter_src'  => 'list',
    'filter_exec' => 'sort -k+4 INFILE > OUTFILE'
  },

}
