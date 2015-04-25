template = {

  # wherigo table
  'wherigo' => {
    'ext'     => 'wig',
    'mime'    => 'text/plain',
    'desc'    => 'wherigo list',
    'templatePre' => "# wherigo list, gaps to be filled in, input to WigToad\n",
    # GCxxxx=CGUID lat lon ..., required for cartridge search outside GeoToad
    'templateWP'  => "<%out.wid%>=<%out.cartridge%>\t" +
      "<%out.latdatapad6%> <%out.londatapad6%>\t" +
      "<%wp.difficulty%>/<%wp.terrain%>/<%wp.size%><%out.premiumOnly%><%out.warnArchiv%><%out.warnAvail%>\t" +
      "\"<%wp.name%>\" by <%wp.creator%>\n"
  },

}
