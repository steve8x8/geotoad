template = {

  # contributed by Steve8x8: table, "tab" extended
  'twitter-old' => {
    'ext'         => 'twt',
    'mime'        => 'text/plain',
    'desc'        =>     'Twitter-ready old',
    'templatePre' => "",
    # output condition: distance must be <= 10km
    'conditionWP' =>
      "\"<%out.relativedistancekm%>\".to_f <= 10",
    'maxlengthWP' => 138,
    'templateWP'  =>
      "coord.info/<%out.wid%>" +
      " <%out.latdegmin%> <%out.londegmin%>" +
      " <%out.nuvi%>" +
      # only ASCII charset allowed
      " \"<%wpTextAscii.name%>\" by <%wpTextAscii.creator%>" +
      " (<%out.cdateshort%>)" +
#     " <%out.relativedistancekm%>" +
      "\n"
    },

  'twitter' => {
    'ext'         => 'twt',
    'mime'        => 'text/plain',
    'desc'        =>     'Twitter-ready with map link',
    'templatePre' => "",
    # output condition: distance must be <= 10km
    'conditionWP' =>
      "\"<%out.relativedistancekm%>\".to_f <= 10",
    'maxlengthWP' => 138,
    'templateWP'  =>
      "coord.info/<%out.wid%>" +
      " maps.google.com/?q=" +
      #"<%out.wid%>@" +
      "<%out.latdatapad5%>,<%out.londatapad5%>" +
      " <%out.nuvi%>" +
      # only ASCII charset allowed
      " \"<%wpTextAscii.name%>\"" +
      " (<%wpTextAscii.creator%>,<%out.cdateshort%>)" +
      " <%out.relativedistancekm%>" +
      "\n"
    },

}
