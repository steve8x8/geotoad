template = {

  'html' => {
    'ext'  => 'html',
    'desc' => 'Simple HTML',
    'templatePre'   =>
      "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n" +
      "<html><head>\n<title><%outEntity.title%></title>\n" +
      "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n" + "</head>\n" +
      "<body link=\"#000099\" vlink=\"#000044\" alink=\"#000099\">\n" +
      "<h3><%outEntity.title%></h3>" +
      "<b><font color=\"#11CC11\">&#x24;</font></b> premium-member only&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#111111\">&Oslash;</font></b> archived&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#CC1111\">&#x229e;</font></b> marked as \"temporarily unavailable\"<br>" +
      "<b><font color=\"#11CC11\">&euro;</font></b> have travelbugs&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#9900CC\">&infin;</font></b> never been found&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#999922\">&sect;</font></b> terrain rating of 3.5+&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#440000\">&uarr;</font></b> difficulty rating of 3.5+&nbsp;&nbsp;&nbsp;" +
      "<b><font color=\"#BB6666\">&hearts;</font></b> fav factor of 3.0+<br>" +
      "<br>\n",
    'templateIndex' => "* <a href=\"#<%out.wid%>\"><%wpEntity.name%></a><br>",
    'usesLocation'  => true,
    'templateWP'    =>
      "\n\n<hr noshade size=\"1\">\n" +
      "<h3><a name=\"<%out.wid%>\"></a><font color=\"#000099\"><%out.symbols%><a href=\"<%wp.url%>\"><%wp.name%></a></font> by <font color=\"#555555\"><%wpEntity.creator%></font> <font color=\"#444444\">(<%out.wid%>)</font></h3>\n" +
      "<a href=\"<%out.maps_url%>\"><%wp.latwritten%> <%wp.lonwritten%></a> <i>near <%out.location%></i><br>" +
      "<font color=\"#339933\"><%wp.type%> (<%wp.size%>) D<%wp.difficulty%>/T<%wp.terrain%> Fav<%wp.favfactor%>(<%wp.favorites%>/<%out.foundcount%>) &rarr;<%out.relativedistance%><br>" +
      "Placed: <%out.cdate%> Last comment: <%wp.last_find_days%> days ago (<%wp.last_find_type%>)</font><br>\n" +
      "Age of information: <%wp.ldays%> days<br>\n" +
      "Attributes: <%out.txtAttrs%><br>\n" +
      "<div>" + # catch runaway stuff like <center>
      "<p><%wp.additional_raw%><%wp.shortdesc%></p>\n" + # font size inside tables?
      "<p><%wp.longdesc%></p>\n" +
      "</div>\n" +
      "<p><font color=\"#555555\"><i><%outEntity.hintdecrypt%></i></font></p>\n" +
      "<div>" + # catch runaway stuff like <center>
      "<p><font color=\"#003300\" size=\"-1\"><%wp.gallery%></font></p>\n" +
      "</div>\n" +
      "<div>" + # catch runaway stuff like <center>
      "<p><font color=\"#330000\" size=\"-1\"><%out.htmllogs%></font></p>\n" +
      "</div>\n",
    'templatePost'  => "</body></html>"
  },

}
