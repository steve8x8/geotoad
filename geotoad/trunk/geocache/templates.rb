# This is our dump templating engine. It only handles really simple text formats at the moment.
# GeoToad 4.0 will have a plugins architecture that replaces this.

$Format = {
        'gpspoint'    => {
            'ext'        => 'gpd',
            'mime'    => 'application/gpspoint',
            'desc'    => 'gpspoint datafile',
            'spacer' => ' ',
            'templatePre'    => "GPSPOINT DATA FILE\ntype=\"fileinfo\"  version=\"1.00\"\n" +
                                            "type=\"programinfo\" program=\"geotoad\" version=\"0.0\"\n",
            'templateWP'        => "type=\"waypoint\" latdata=\"<%wp.latdata%>\" londata=\"<%wp.londata%>\" " +
                                             "name=\"<%out.id%>\" comment=\"<%wp.name%>\" " +
                                            "symbol=\"flag\"  display_option=\"symbol+name\"\n",
        },
        'easygps' => {
            'ext'        => 'loc',
            'mime'    => 'application/easygps',
            'desc'    => 'Geocaching.com .loc XML file',
            'templatePre'    => "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><loc version=\"1.0\" src=\"EasyGPS\">",
            'templateWP'    => "<waypoint><name id=\"<%out.id%>\"><![CDATA[<%wp.name%>]]></name>" +
                                            "<coord lat=\"<%wp.latdata%>\" lon=\"<%wp.londata%>\"/>" +
                                            "<type>geocache</type><link text=\"Cache Details\"><%out.url%></link></waypoint>",
            'templatePost'    => '</loc>',
            'spacer' => ' ',
        },


        # ** The gpx.hints be removed for GeoToad 4.0, when we use a real templating engine that can do loops **
        'gpx'    => {
            'ext'        => 'gpx',
            'mime'    => 'text/ascii',
            'desc'    => 'GPX Geocaching XML',
            'spacer'    => "\r\n",
            'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n" +
            "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0 http://www.groundspeak.com/cache/1/0/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\r\n" +
            "<desc><%outXML.title%></desc>\r\n" +
            "<author>GeoToad <%out.version%></author>\r\n" +
            "<email>geotoad@toadstool.se</email>\r\n" +
            "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".0000000-00:00</time>\r\n" +
            "<keywords>cache, geocache, groundspeak, geotoad</keywords>\r\n",

            'templateWP'    => "<wpt lat=\"<%wp.latdata%>\" lon=\"<%wp.londata%>\">\r\n" +
            "  <time>2003-05-20T00:00:00.0000000-07:00</time>\r\n" +
            "  <name><%out.id%></name>\r\n" +
            "  <desc><%wpXML.name%> by <%wpXML.creator%>, <%wp.type%> (<%wp.difficulty%>/<%wp.terrain%>)</desc>\r\n" +
            "  <url><%out.url%></url>\r\n" +
            "  <urlname><%wpXML.name%> by <%wpXML.creator%></urlname>\r\n" +
            "  <sym>Geocache</sym><type>Geocache</type>\r\n" +
            "  <groundspeak:cache id=\"<%wp.sid%>\" available=\"True\" archived=\"False\" xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0\">\r\n" +
            "  <groundspeak:name><%wpXML.name%></groundspeak:name>\r\n" +
			"  <groundspeak:full_name><%wpXML.name%></groundspeak:full_name>\r\n"+
            "  <groundspeak:placed_by><%wpXML.creator%></groundspeak:placed_by>\r\n" +
            "  <groundspeak:owner id=\"89944\"><%wpXML.creator%></groundspeak:owner>\r\n" +
            "  <groundspeak:type><%wp.type%></groundspeak:type>\r\n" +
            "  <groundspeak:container><%wp.container%></groundspeak:container>\r\n" +
            "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\r\n" +
            "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\r\n" +
            "  <groundspeak:country><%wp.country%></groundspeak:country>\r\n" +
            "  <groundspeak:state><%wp.state%></groundspeak:state>\r\n" +
            "  <groundspeak:short_description html=\"False\"><%outXML.shortdesc%></groundspeak:short_description>\r\n" +
            "  <groundspeak:long_description html=\"False\"><%outXML.longdesc%></groundspeak:long_description>\r\n" +
            "  <groundspeak:encoded_hints><%wpXML.hint%></groundspeak:encoded_hints>\r\n" +
            "  <groundspeak:logs>\r\n" +
            "  <%out.gpxlogs%>\r\n" +
            "  </groundspeak:logs>\r\n" +
            "  <groundspeak:travelbugs />\r\n" +
            "  </groundspeak:cache>\r\n" +
            "</wpt>\r\n",
            'templatePost'    => " </gpx>\r\n"
        },

        'html'    => {
            'ext'        => 'html',
            'mime'    => 'text/html',
            'desc'    => 'Simple HTML',
            'spacer'    => "<br>&nbsp;\n",
            'templatePre' => "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n" +
                "<html><head>\n<title><%out.title%></title>\n" +
                "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n" + "</head>\n" +
                "<body link=\"#000099\" vlink=\"#000044\" alink=\"#000099\">\n" +
                "<h3><%out.title%></h3>" +
                "<b><font color=\"#11CC11\">$</font></b> have travelbugs&nbsp;&nbsp;&nbsp;" +
                "<b><font color=\"#9900CC\">@</font></b> never been found&nbsp;&nbsp;&nbsp;" +
                "<b><font color=\"#229999\">%</font></b> terrain rating of 3.5+&nbsp;&nbsp;&nbsp;" +
                "<b><font color=\"#BB0000\">&gt;</font></b> difficulty rating of 3.5+<br>" +
                # Not yet ready for consumption
                #"<b><font color=\"#333333\">--</font></b> comments seem negative&nbsp;&nbsp;&nbsp;" +
                #"<b><font color=\"#000000\">++</font></b> comments seem very positive" +

                "<font color=\"#555555\" size=\"1\"><pre>Decryption Key (letter above equals below, and vice versa)

A|B|C|D|E|F|G|H|I|J|K|L|M
-------------------------
N|O|P|Q|R|S|T|U|V|W|X|Y|Z</pre></font><br>",
            'templateIndex' => "* <a href=\"#<%out.wid%>\"><%wpEntity.name%></a><br>",
            'templateWP'    =>
                "\n\n<hr noshade size=\"1\">\n<a name=\"<%out.wid%>\"></a><font color=\"#000099\"><a href=\"<%out.url%>\"><big><b><%wpEntity.name%>&nbsp;<%out.symbols%></b></big></a></font><br>\n" +
                "<font color=\"#555555\"><b><%wpEntity.creator%></b></font>, <%wp.latwritten%> <%wp.lonwritten%><br>" +
                "<font color=\"#339933\"><%wp.type%> D<%wp.difficulty%>/T<%wp.terrain%> <%out.relativedistance%><br>" +
                "placed: <%wp.cdate%> last comment: <%wp.mdays%> days ago (<%wp.comment0Type%>)</font><br>" +
                "<p><%outEntity.details%></p>\n" +
                "<p><font color=\"#555555\"><%out.hint%></font></p>\n",
            'templatePost'    => "</body></html>"
        },


        'html-decrypt'    => {
            'ext'        => 'html',
            'mime'    => 'text/html',
            'desc'    => 'Simple HTML with hint decrypted',
            'spacer'    => "<br>&nbsp;\n",
            'templatePre' => "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n" +
            "<html><head>\n<title><%out.title%></title>\n" +
            "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\n" + "</head>\n" +
            "<body link=\"#000099\" vlink=\"#000044\" alink=\"#000099\">\n" +
            "<h3><%out.title%></h3>" +
            "<b><font color=\"#11CC11\">$</font></b> have travelbugs&nbsp;&nbsp;&nbsp;" +
            "<b><font color=\"#9900CC\">@</font></b> never been found&nbsp;&nbsp;&nbsp;" +
            "<b><font color=\"#229999\">%</font></b> terrain rating of 3.5+&nbsp;&nbsp;&nbsp;" +
            "<b><font color=\"#BB0000\">&gt;</font></b> difficulty rating of 3.5+<br>",
            # Not yet ready for consumption
            #"<b><font color=\"#333333\">--</font></b> comments seem negative&nbsp;&nbsp;&nbsp;" +
            #"<b><font color=\"#000000\">++</font></b> comments seem very positive" +
            'templateIndex' => "* <a href=\"#<%out.wid%>\"><%wpEntity.name%></a><br>",
            'templateWP'    =>
            "\n\n<hr noshade size=\"1\">\n<a name=\"<%out.wid%>\"></a><font color=\"#000099\"><a href=\"<%out.url%>\"><big><b><%wpEntity.name%>&nbsp;<%out.symbols%></b></big></a></font><br>\n" +
            "<font color=\"#555555\"><b><%wpEntity.creator%></b></font>, <%wp.latwritten%> <%wp.lonwritten%><br>" +
            "<font color=\"#339933\"><%wp.type%> D<%wp.difficulty%>/T<%wp.terrain%> <%out.relativedistance%><br>" +
             "placed: <%wp.cdate%> last comment: <%wp.mdays%> days ago (<%wp.comment0Type%>)</font><br>" +
            "<p><%outEntity.details%></p>\n" +
            "<p><font color=\"#555555\"><%out.hintdecrypt%></font></p>\n",
          'templatePost'    => "</body></html>"
        },


        'text'    => {
            'ext'        => 'txt',
            'mime'    => 'text/plain',
            'desc'    =>     'Plain ASCII',
            'spacer'    => "\r\n",
            'templatePre' =>  "== <%out.title%>\r\n\r\nDecryption Key (letter above equals below, and vice versa)\r\n\r\nA|B|C|D|E|F|G|H|I|J|K|L|M\r\n-------------------------\r\nN|O|P|Q|R|S|T|U|V|W|X|Y|Z\r\n\r\n\r\n",
            'templateWP'    => "----------------------------------------------------------------\r\n" +
		"* <%wp.name%>\" (<%out.wid%>) by <%wp.creator%>\r\n" +
                "Difficulty: <%wp.difficulty%>, Terrain: <%wp.terrain%>\r\n" +
                "Lat: <%wp.latwritten%> Lon: <%wp.lonwritten%>\r\n" +
                "Type: <%wp.type%> <%out.relativedistance%>\r\n" +
                "Creation: <%wp.cdate%>, Last comment: <%wp.mdays%> days ago (<%wp.comment0Type%>)\r\n" +
                "\r\n<%out.details%>\r\n" +
                "\r\n<%out.hint%>\r\n\r\n\r\n\r\n"
        },

        'text-decrypt'    => {
        'ext'        => 'txt',
        'mime'    => 'text/plain',
        'desc'    =>     'Plain ASCII with hint decrypted',
        'spacer'    => "\r\n",
        'templatePre' =>  "== <%out.title%>\r\n\r\nDecryption Key (letter above equals below, and vice versa)\r\n\r\nA|B|C|D|E|F|G|H|I|J|K|L|M\r\n-------------------------\r\nN|O|P|Q|R|S|T|U|V|W|X|Y|Z\r\n\r\n\r\n",
        'templateWP'    => "----------------------------------------------------------------\r\n" +
		"* <%wp.name%>\" (<%out.wid%>) by <%wp.creator%>\r\n" +
        "Difficulty: <%wp.difficulty%>, Terrain: <%wp.terrain%>\r\n" +
        "Lat: <%wp.latwritten%> Lon: <%wp.lonwritten%>\r\n" +
        "Type: <%wp.type%> <%out.relativedistance%>\r\n" +
        "Creation: <%wp.cdate%>, Last comment: <%wp.mdays%> days ago (<%wp.comment0Type%>)\r\n" +
        "\r\n<%out.details%>\r\n" +
        "\r\n<%out.hint%>\r\n\r\n\r\n\r\n"
    },


        'tab'    => {
            'ext'        => 'txt',
            'mime'    => 'text/plain',
            'desc'    =>     'Tab Delimited (GPS Connect)',
            'spacer'    => "",
            'templatePre' => "",
            'templateWP'    => "<%out.id%>\t<%wp.latdata%>\t<%wp.londata%>\t0\r\n"
        },

        'csv'    => {
            'ext'        => 'txt',
            'mime'    => 'text/plain',
            'desc'    => 'CSV for spreadsheet imports',
            'spacer'    => "",
            'templatePre' => "\"Name\",\"Waypoint ID\",\"Creator\",\"Difficulty\",\"Terrain\"," +
                                            "\"Latitude\",\"Longitude\",\"Type\",\"Creation Date\",\"Details\"\r\n",
            'templateWP'    => "\"<%wp.name%>\",\"<%out.wid%>\",\"<%wp.creator%>\"," +
 		"<%wp.difficulty%>,<%wp.terrain%>,\"<%wp.latwritten%>\",\"<%wp.lonwritten%>\"," +
                "\"<%wp.type%>\",\"<%wp.cdate%>\",\"<%out.details%>\"\r\n"
        },

        'vcf'    => {
            'ext'                        => 'vcf',
            'mime'                    => 'text/x-vcard',
            'detailsLength'    => 2000,
            'desc'    => 'VCF for iPod Contacts export',
            'spacer' => ' ',
            'templatePre'        => "",
            'templateWP'        => "BEGIN:vCard\nVERSION:2.1\n" +
                 "FN:G<%out.average%> <%out.id%>\nN:G<%out.average%>;<%out.id%>\n" +
                 "NOTE:<%out.details%><%out.hint%>\n" +
                 "ADD:<%wp.latwritten%>;<%wp.lonwritten%>;;<%wp.state%>;\n" +
                 "TEL;HOME:<%out.wid%>\nEMAIL;INTERNET:<%wp.difficulty%>@<%wp.terrain%>\n" +
                 "TITLE:<%wp.name%>\nORG:<%wp.type%> <%wp.cdate%>\nEND:vCard\n",
        },

        'gpsman' => {
            'ext'        => 'gpm',
            'mime'    => 'application/gpsman',
            'desc'    => 'GPSman datafile',
            'spacer' => '',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsman -F OUTFILE'
        },

        'mapsend' => {
            'ext'        => 'mps',
            'mime'    => 'application/mapsend',
            'desc'    => 'Magellan MapSend software',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx  -f INFILE -o mapsend -F OUTFILE'
        },

        'pcx' => {
            'ext'        => 'pcx',
            'mime'    => 'application/pcx',
            'desc'    => 'Garmin PCX5',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o pcx -F OUTFILE'
        },

        'gpsutil' => {
            'ext'        => 'gpu',
            'mime'    => 'application/gpsutil',
            'desc'    => 'gpsutil',
            'required' => 'gpsbabel',
            'spacer' => '',
                        'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsutil -F OUTFILE'
        },

        'tiger' => {
            'ext'        => 'tgr',
            'mime'    => 'application/x-tiger',
            'desc'    => 'U.S. Census Bureau Tiger Mapping Service Data',
            'spacer'    => "\n",
            'templatePre' =>  "#tms-marker\n",
            'templateWP' => "<%out.londatapadded%>,<%out.latdatapadded%>:redpin:<%wp.name%> by <%wp.creator%>, <%wp.type%> (<%wp.difficulty%>/<%wp.terrain%>)\n"
        },

        'xmap' => {
            'ext'        => 'tgr',
            'mime'    => 'application/xmap',
            'desc'    => 'Delorme Topo USA4/XMap Conduit',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o xmap -F OUTFILE'
        },

        'dna' => {
            'ext'        => 'dna',
            'mime'    => 'application/xmap',
            'desc'    => 'Navitrak DNA marker',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
        },

        'psp' => {
            'ext'        => 'psp',
            'mime'    => 'application/psp',
            'desc'    => 'Microsoft PocketStreets 2002 Pushpin',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o psp -F OUTFILE'
        },

        'cetus' => {
            'ext'        => 'cet',
            'mime'    => 'application/cetus',
            'desc'    => 'Cetus for PalmOS',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o cetus -F OUTFILE'
        },
        'gpspilot' => {
            'ext'        => 'gps',
            'mime'    => 'application/gpspilot',
            'desc'    => 'GPSPilot for PalmOS',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
        },
        'magnav' => {
            'ext'        => 'mgv',
            'mime'    => 'application/magnav',
            'desc'    => 'Magellan NAV Companion for PalmOS',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o magnav -F OUTFILE'
        },

        'mxf' => {
            'ext'        => 'mxf',
            'mime'    => 'application/mxf',
            'desc'    => 'MapTech Exchange',
            'spacer'    => "\n",
           'templatePre' => '',
           'templateWP' => "<%out.latdatapad5%>, <%out.londatapad5%>, \"<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)\", \"<%out.wid%>\", \"<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>)\", ff0000, 47\r\n"
        },


        'holux' => {
            'ext'        => 'wpo',
            'mime'    => 'application/holux',
            'desc'    => 'Holux gm-100 ',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o holux -F OUTFILE'
        },

        # Tested by efnord @ EFnet.. Thanks!
        'ozi' => {
            'ext'        => 'wpt',
            'mime'    => 'application/x-ozi-wpt',
            'desc'    => 'OziExplorer',
            'spacer'    => "\r\n",
            'templatePre' => "OziExplorer Waypoint File Version 1.1\r\n" +
            "WGS 84\r\n" +
            "Reserved 2\r\n" +
            "Reserved 3\r\n",
            'templateWP' => "<%out.counter%>,<%out.wid%>,<%out.latdatapad6%>,<%out.londatapad6%>,37761.29167,0,1,3,0,65535,<%wp.name%> by <%wp.creator%> (<%wp.type%> - <%wp.difficulty%>/<%wp.terrain%>),0,0,0,-777,6,0,17\r\n"
        },

        'tpg' => {
            'ext'        => 'tpg',
            'mime'    => 'application/tpg',
            'desc'    => 'National Geographic Topo',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tpg -F OUTFILE'
        },
        'tmpro' => {
            'ext'        => 'tmp',
            'mime'    => 'application/tmpro',
            'desc'    => 'TopoMapPro Places',
            'required' => 'gpsbabel',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tmpro -F OUTFILE'
        },

        'gpsdrive' => {
           'ext'        => 'sav',
           'mime'    => 'application/gpsdrive',
           'spacer' => '',
           'desc'    => 'GpsDrive',
           'spacer'    => "\r\n",
           'templatePre' => '',
           'templateWP' => "<%out.wid%> <%out.latdatapad5%> <%out.londatapad5%> Geocache\n"
        },

        'cachemate' => {
            'ext'        => 'pdb',
            'mime'    => 'application/cachemate',
            'required' => 'cmconvert',
            'spacer' => '',
            'desc'    => 'CacheMate for PalmOS',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'cmconvert -o OUTFILE INFILE'
        },

        'delorme' => {
            'ext'          => 'txt',
            'mime'         => 'application/delorme',
            'desc'         => 'DeLorme TXT import datafile',
            'spacer'       => ' ',
            'templatePre'  => "BEGIN SYMBOL\n",
            'templateWP'   => "<%wp.latdata%>,<%wp.londata%>," +
		"<%out.id%>\{URL=<%out.url%>\},<%wp.type%>\n",
            'templatePost' => "END",
        },

         'delorme-nourl' => {
            'ext'          => 'txt',
            'mime'         => 'application/delorme',
            'desc'         => 'DeLorme TXT import datafile without URL',
            'spacer'       => ' ',
            'templatePre'  => "BEGIN SYMBOL\n",
            'templateWP'   => "<%wp.latdata%>,<%wp.londata%>," +
                              "<%out.id%>,<%wp.type%>\n",
            'templatePost' => "END",
        }
}
