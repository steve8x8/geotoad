template = {
  # contributed by Steve8x8: table, "tab" extended
  'list'    => {
    'ext'        => 'lst',
    'mime'    => 'text/plain',
    'desc'    =>     'whitespace delimited, detailed table',
    'templatePre' => "",
    'templateWP'    => "<%out.id%>\t" +
      "<%out.latdatapad5%> <%out.londatapad5%> " +
      "<%out.cdate%> " +
      "<%wp.difficulty%>/<%wp.terrain%><%out.warnArchiv%><%out.warnAvail%>\t" +
      "<%wp.type%>\t" +
      "<%out.relativedistancekm%>\t" +
      "<%out.size%>\t" + # testing only
      "\"<%wp.name%>\" by <%wp.creator%>\n"
  },
}
