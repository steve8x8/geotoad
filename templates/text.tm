template = {

  'text' => {
    'ext'  => 'txt',
    'desc' =>     'Plain ASCII',
    'templatePre' =>
      "== <%out.title%>\n\n",
    'templateWP'  =>
      "\n" +
      "----------------------------------------------------------------\n" +
      "=> <%wpText.name%> (<%out.wid%>) by <%wpText.creator%> <=\n" +
      "----------------------------------------------------------------\n\n" +
      "Lat: <%wp.latwritten%> Lon: <%wp.lonwritten%>\n" +
      "Difficulty: <%wp.difficulty%>, Terrain: <%wp.terrain%>, FavFactor: <%wp.favfactor%>\n" +
      "Type/Size: <%wp.type%> (<%wp.size%>), Distance: <%out.relativedistance%>\n" +
      "Creation: <%out.cdate%>, Last comment: <%wp.last_find_days%> days ago (<%wp.last_find_type%>)\n\n" +
      "Age of info: <%wp.ldays%> days\n" +
      "Attributes: <%out.txtAttrs%>\n" +
      "State: <%out.premiumOnly%><%out.warnArchiv%><%out.warnAvail%>\n" +
      "Short: <%wpText.shortdesc%>\n" +
      "Long:\n<%wpText.longdesc%>\n\n" +
      "Hint: <%outEntity.hintdecrypt%>\n\n" +
      "Logs:\n<%out.textlogs%>\n"
  },

}
