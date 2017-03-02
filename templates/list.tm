template = {

  # contributed by Steve8x8: table, "tab" extended
  'list' => {
    'ext'         => 'lst',
    'desc'        =>     'Table, whitespace delimited',
    'templatePre' => "",
    'templateWP'  =>
      "<%out.id%>\t" +
      "<%out.latdatapad5%> <%out.londatapad5%> " +
      "<%out.cdate%> " +
      "<%wp.difficulty%>/<%wp.terrain%><%out.premiumOnly%><%out.warnArchiv%><%out.warnAvail%>\t" +
      "<%out.type8%>\t" +
      "<%out.relativedistancekm%>\t" +
      "<%out.size%>\t" + # testing only
      "\"<%wp.name%>\" by <%wp.creator%>\n"
  },

}
