template = {

  # template taken from geotoad-3.9.6/lib/templates.rb,
  # (dropped later), slightly reformatted
  # WARNING: This template doesn't work anymore!!!
  'vcf-3.9.6' => {
    'ext'           => 'vcf',
    'detailsLength' => 2000,
    'desc'          => 'VCF for iPod Contacts export',
    'templatePre'   => "",
    'templateWP'    =>
      "BEGIN:vCard\n" +
      "VERSION:2.1\n" +
      # average = (difficulty + terrain)/2, rounded down
      "FN:G<%out.average%> <%out.id%>\n" +
      "N:G<%out.average%>;<%out.id%>\n" +
      # details = shortdesc + longdesc, truncated to 2000 chars
      "NOTE:<%out.details%><%out.hintdecrypt%>\n" +
      "ADD:<%wp.latwritten%>;<%wp.lonwritten%>;;<%wp.state%>;\n" +
      "TEL;HOME:<%out.wid%>\n" +
      "EMAIL;INTERNET:<%wp.difficulty%>@<%wp.terrain%>\n" +
      "TITLE:<%wp.name%>\n" +
      "ORG:<%wp.type%> <%wp.cdate%>\n" +
      "END:vCard\n",
  },

  # rewritten using pre-3.11.0 template, WP:VCard, own address book
  # iPod seems to be limited to 2000 characters (per entry?)
  # most entries are duplicated - sort this out
  # some entries may need "CHARSET=UTF-8"?
  'vcf' => {
    'ext'           => 'vcf',
    'desc'          => 'VCF vCard2.1 for iPod Contacts export',
    'usesLocation'  => true,
    'templatePre'   => "",
    'templateWP'    =>
      "BEGIN:VCARD\n" +
      "VERSION:2.1\n" +
      "N:<%out.wid%>;<%wp.type%>;<%wp.size%>;;\n" +
      "FN:D<%wp.difficulty%>/T<%wp.terrain%>/<%out.size%> <%wp.type%> <%out.wid%> <%out.pad%>\n" +
      "ORG:<%wpText.creator%>;<%out.cdate%>\n" +
      "TITLE:<%wp.name%>\n" +
      "NOTE:<%out.txtAttrs%>;Hint:<%out.hintdecrypt%>;\n" +
      "GEO:<%out.latdatapad6%>;<%out.londatapad6%>\n" +
      "ADR;HOME:;;<%out.latdegmin%>, <%out.londegmin%>;<%out.location%>;<%wp.state%>;<%wp.country%>\n" +
      "TEL;HOME:<%out.wid%>\n" +
      "EMAIL;PREF:D<%wp.difficulty%>_T<%wp.terrain%>_<%out.size%>@<%wp.type%>.gc\n" +
      "CATEGORIES:Geocaches,<%wp.fulltype%>,D<%wp.difficulty%>,T<%wp.terrain%>\n" +
      "END:VCARD\n",
  },
}
