template = {

  'delorme' => {
    'ext'          => 'txt',
    'desc'         => 'DeLorme TXT import datafile',
    'templatePre'  => "BEGIN SYMBOL\n",
    'templateWP'   =>
      "<%out.latdatapad6%>,<%out.londatapad6%>," +
      "<%out.id%>\{URL=<%wp.url%>\},<%wp.type%>\n",
    'templatePost' => "END",
  },

  'delorme-nourl' => {
    'ext'          => 'txt',
    'desc'         => 'DeLorme TXT import datafile without URL',
    'templatePre'  => "BEGIN SYMBOL\n",
    'templateWP'   =>
      "<%out.latdatapad6%>,<%out.londatapad6%>," +
      "<%out.id%>,<%wp.type%>\n",
    'templatePost' => "END",
  },

}
