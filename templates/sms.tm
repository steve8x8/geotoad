template = {

  # contributed by regengott.nass
  'sms' => {
    'ext'  => 'sms',
    'desc' => 'SMS (type 1)',
    'templatePre' => "",
    'templateWP'  =>
      "<%wpText.name%>,<%out.wid%>,<%wpText.creator%>," +
      "D<%wp.difficulty%>,T<%wp.terrain%>,<%out.relativedistance%>,<%wp.latwritten%>,<%wp.lonwritten%>," +
      "<%wp.type%>,<%wp.size%>\n"
  },

  # derived from "sms" but reordered and ready for smartphone
  'sms2' => {
    'ext'  => 'sms2',
    'desc' => 'SMS (type 2)',
    'templatePre' => "",
    'templateWP'  =>
      "coord.info/<%out.wid%>" +
      " <%wp.latwritten%> <%wp.lonwritten%>" +
      " (<%out.relativedistancekm%>)" +
      " <%wp.type%> D<%wp.difficulty%>/T<%wp.terrain%>/<%wp.size%> -" +
      " <%wpText.creator%>: <%wpText.name%>\n"
  },

  # derived from "sms" as well, different coord representation
  'sms3' => {
    'ext'  => 'sms3',
    'desc' => 'SMS (type 3)',
    'templatePre' => "",
    'templateWP'  =>
      "coord.info/<%out.wid%> (<%out.cdateshort%>)" +
      " <%out.latdegmin%> <%out.londegmin%>" +
      " (<%out.relativedistancekm%>)" +
      " <%out.nuvi%> -" +
      " \"<%wpText.name%>\" by <%wpText.creator%>\n"
  },

  # derived from "sms" as well, different coord representation
  'sms4' => {
    'ext'         => 'sms4',
    'desc'        => 'SMS (type 4)',
    'templatePre' => "",
    'templateWP'  =>
      "coord.info/<%out.wid%>" +
      " <%out.latdegmin%> <%out.londegmin%>" +
      " <%out.nuvi%> -" +
      " \"<%wpText.name%>\"" +
      " (<%wpText.creator%>" +
      " <%out.cdateshort%>)" +
      "\n"
  },

}
