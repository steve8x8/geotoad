template = {
  # contributed by regengott.nass
  'sms' => {
    'ext'         => 'sms',
    'mime'        => 'text/plain',
    'desc'        => '(SMS) Shorten relevant infos for SMS info',
    'spacer'      => "",
    'templatePre' => "",
    'templateWP'  => "<%wpText.name%>,<%out.wid%>,<%wpText.creator%>," +
      "D<%wp.difficulty%>,T<%wp.terrain%>,<%out.relativedistance%>,<%wp.latwritten%>,<%wp.lonwritten%>," +
      "<%wp.type%>,<%wp.size%>\n"
  },
  # derived from "sms" but reordered and ready for smartphone
  'sms2' => {
    'ext'         => 'sms2',
    'mime'        => 'text/plain',
    'desc'        => '(SMS) Shorten relevant infos for SMS info',
    'spacer'      => "",
    'templatePre' => "",
    'templateWP'  => "coord.info/<%out.wid%>" +
      " <%wp.latwritten%> <%wp.lonwritten%>" +
      " (<%out.relativedistancekm%>)" +
      " <%wp.type%> D<%wp.difficulty%>/T<%wp.terrain%>/<%wp.size%> -" +
      " <%wpText.creator%>: <%wpText.name%>\n"
  },
}
