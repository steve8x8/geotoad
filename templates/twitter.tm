template = {

  # contributed by Steve8x8: table, "tab" extended
  'twitter' => {
    'ext'         => 'twt',
    'mime'        => 'text/plain',
    'desc'        =>     'Twitter-ready',
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

}
