$Format = {
        'gpspoint'    => {
            'ext'        => 'gpd',
            'mime'    => 'application/gpspoint',
            'desc'    => 'gpspoint datafile',
            'spacer' => ' ',
            'templatePre'    => "GPSPOINT DATA FILE\ntype=\"fileinfo\"  version=\"1.00\"\n" +
                                            "type=\"programinfo\" program=\"geotoad\" version=\"0.0\"\n",
            'templateWP'        => "type=\"waypoint\" latdata=\"<%wp.latdata%>\" londata=\"<%wp.londata%>\"" +
                                             "name=\"<%out.id%>\" comment=\"<%wp.name%>\"" +
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


        # experimental internal method. Does not yet validate because we need to encode
        # certain text into valid XML entities.
        'gpx'    => {
            'ext'        => 'gpx',
            'mime'    => 'text/ascii',
            'desc'    => 'GPX Geocaching XML',
            'spacer'    => "\r\n",
            'templatePre' => "<?xml version=\"1.0\" encoding=\"utf-8\"?>\r\n" +
            "<gpx xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" version=\"1.0\" creator=\"GeoToad\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd http://www.groundspeak.com/cache/1/0 http://www.groundspeak.com/cache/1/0/cache.xsd\" xmlns=\"http://www.topografix.com/GPX/1/0\">\r\n" +
            "<desc><%outEntity.title%></desc>\r\n" +
            "<author>GeoToad #{$VERSION}</author>\r\n" +
            "<email>geotoad@toadstool.se</email>\r\n" +
            "<time>" + Time.new.gmtime.strftime("%Y-%m-%dT%H:%M:%S")  + ".0000000-00:00</time>\r\n" +
            "<keywords>cache, geocache, groundspeak, geotoad</keywords>\r\n",

            'templateWP'    => "<wpt lat=\"<%wp.latdata%>\" lon=\"<%wp.londata%>\">\r\n" +
            "  <time>2003-06-18T00:00:00.0000000-07:00</time>\r\n" +
            "  <name><%out.id%></name>\r\n" +
            "  <desc><%wpEntity.name%> by <%wpEntity.creator%>, <%wp.type%> Cache (<%wp.difficulty%>/<%wp.terrain%>)</desc>\r\n" +
            "  <url><%out.url%></url>\r\n" +
            "  <urlname><%wpEntity.name%> by <%wpEntity.creator%></urlname>\r\n" +
            "  <sym>Geocache</sym><type>Geocache</type>\r\n" +
            "  <groundspeak:cache id=\"<%wp.sid%>\" available=\"True\" archived=\"False\" xmlns:groundspeak=\"http://www.groundspeak.com/cache/1/0\">\r\n" +
            "  <groundspeak:name><%wpEntity.name%></groundspeak:name>\r\n" +
			"  <groundspeak:full_name><%wpEntity.name%></groundspeak:full_name>\r\n"+
            "  <groundspeak:placed_by><%wpEntity.creator%></groundspeak:placed_by>\r\n" +
            "  <groundspeak:owner id=\"00000\"><%wpEntity.creator%></groundspeak:owner>\r\n" +
            "  <groundspeak:type><%wp.type%> Cache</groundspeak:type>\r\n" +
            "  <groundspeak:container><%wp.type%></groundspeak:container>\r\n" +
            "  <groundspeak:difficulty><%wp.difficulty%></groundspeak:difficulty>\r\n" +
            "  <groundspeak:terrain><%wp.terrain%></groundspeak:terrain>\r\n" +
            "  <groundspeak:country><%wp.country%></groundspeak:country>\r\n" +
            "  <groundspeak:state><%wp.state%></groundspeak:state>\r\n" +
            "  <groundspeak:short_description html=\"False\">-</groundspeak:short_description>\r\n" +
            "  <groundspeak:long_description html=\"False\"><%outEntity.details%></groundspeak:long_description>\r\n" +
            "  <groundspeak:encoded_hints><%outEntity.hint%></groundspeak:encoded_hints>\r\n" +
            "  <groundspeak:logs>\r\n" +
            "    <groundspeak:log id=\"00000\">\r\n" +
            "      <groundspeak:date>XXX</groundspeak:date>\r\n" +
            "      <groundspeak:type>Found it</groundspeak:type>\r\n" +
            "      <groundspeak:finder id=\"000000\">Unsupported</groundspeak:finder>\r\n" +
            "      <groundspeak:text encoded=\"False\">Comments not yet supported</groundspeak:text>\r\n" +
            "    </groundspeak:log>\r\n" +
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
                "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n" + "</head>\n" +
                "<body link=\"#000099\" vlink=\"#000044\" alink=\"#000099\">\n" +
                "<h3><%out.title%></h3>" +
                "<b><font color=\"#11CC11\">$</font></b> have travelbugs<br>" +
                "<b><font color=\"#9900CC\">@</font></b> have never been found<br>" +
                "<b><font color=\"#229999\">%</font></b> have a terrain rating of 3.5+<br>" +
                "<b><font color=\"#BB0000\">+</font></b> have a difficulty rating of 3.5+<br>",

            'templateIndex' => "* <a href=\"#<%out.wid%>\"><%wpEntity.name%></a><br>",
            'templateWP'    =>
                "\n\n<hr noshade size=\"1\">\n<a name=\"<%out.wid%>\"></a><font color=\"#000099\"><a href=\"<%out.url%>\"><big><b><%wpEntity.name%><%out.symbols%></b></big></a></font><br>\n" +
                "<font color=\"#555555\"><b><%wpEntity.creator%></b></font>, <%wp.latwritten%> <%wp.lonwritten%><br>" +
                "<font color=\"#339933\"><%wp.type%> D<%wp.difficulty%>/T<%wp.terrain%> <%out.relativedistance%><br>" +
                "placed: <%wp.cdate%> last: <%wp.mdays%> days ago</font><br>" +
                "<p><%outEntity.details%></p>\n" +
                "<p><font color=\"#555555\"><%out.hint%></font></p>\n",
            'templatePost'    => "</body></html>"
        },


        'text'    => {
            'ext'        => 'txt',
            'mime'    => 'text/plain',
            'desc'    =>     'Plain ASCII',
            'spacer'    => "\r\n",
            'templatePre' => "",
            'templateWP'    => "----------------------------------------------------------------\n" +
		"* <%wp.name%>\" (<%out.wid%>) by <%wp.creator%>\r\n" +
                "Difficulty: <%wp.difficulty%>, Terrain: <%wp.terrain%>\r\n" +
                "Lat: <%wp.latwritten%> Lon: <%wp.lonwritten%>\r\n" +
                "Type: <%wp.type%> <%out.relativedistance%>\r\n" +
                "Creation: <%wp.cdate%>, Last found: <%wp.mdays%> days ago\r\n" +
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
            'ext'        => 'csv',
            'mime'    => 'text/plain',
            'desc'    => 'CSV for spreadsheet imports',
            'spacer'    => "",
            'templatePre' => "\"Name\",\"Waypoint ID\",\"Creator\",\"Difficulty\",\"Terrain\"," +
                                            "\"Latitude\",\"Longitude\",\"Type\",\"Creation Date\", \"Details\"\r\n",
            'templateWP'    => "\"<%wp.name%>\",\"<%out.wid%>\",\"<%wp.creator%>\"," +
                "<%wp.difficulty%>,<%wp.terrain%>,<%wp.latwritten%>,<%wp.lonwritten%>," +
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
            'desc'    => 'GPSman datafile (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsman -F OUTFILE'
        },

        'mapsend' => {
            'ext'        => 'mps',
            'mime'    => 'application/mapsend',
            'desc'    => 'Magellan MapSend software (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx  -f INFILE -o mapsend -F OUTFILE'
        },

        'pcx' => {
            'ext'        => 'pcx',
            'mime'    => 'application/pcx',
            'desc'    => 'Garmin PCX5 (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o pcx -F OUTFILE'
        },

        'gpsutil' => {
            'ext'        => 'gpu',
            'mime'    => 'application/gpsutil',
            'desc'    => 'gpsutil (gpsbabel)',
            'spacer' => '',
                        'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsutil -F OUTFILE'
        },

        'tiger' => {
            'ext'        => 'tgr',
            'mime'    => 'application/xtiger',
            'desc'    => 'U.S. Census Bureau Tiger Mapping Service Data (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tiger -F OUTFILE'
        },

        'xmap' => {
            'ext'        => 'tgr',
            'mime'    => 'application/xmap',
            'desc'    => 'Delorme Topo USA4/XMap Conduit (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o xmap -F OUTFILE'
        },

        'dna' => {
            'ext'        => 'dna',
            'mime'    => 'application/xmap',
            'desc'    => 'Navitrak DNA marker (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
        },

        'psp' => {
            'ext'        => 'psp',
            'mime'    => 'application/psp',
            'desc'    => 'Microsoft PocketStreets 2002 Pushpin (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o psp -F OUTFILE'
        },

        'cetus' => {
            'ext'        => 'cet',
            'mime'    => 'application/cetus',
            'desc'    => 'Cetus for PalmOS (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o cetus -F OUTFILE'
        },
        'gpspilot' => {
            'ext'        => 'gps',
            'mime'    => 'application/gpspilot',
            'desc'    => 'GPSPilot for PalmOS (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o dna -F OUTFILE'
        },
        'magnav' => {
            'ext'        => 'mgv',
            'mime'    => 'application/magnav',
            'desc'    => 'Magellan NAV Companion for PalmOS (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o magnav -F OUTFILE'
        },
        'mxf' => {
            'ext'        => 'mxf',
            'mime'    => 'application/mxf',
            'desc'    => 'MapTech Exchange (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o mxf -F OUTFILE'
        },
        'holux' => {
            'ext'        => 'wpo',
            'mime'    => 'application/holux',
            'desc'    => 'Holux gm-100  (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o wpo -F OUTFILE'
        },
        'ozi' => {
            'ext'        => 'ozi',
            'mime'    => 'application/ozi',
            'desc'    => 'OziExplorer (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o ozi -F OUTFILE'
        },
        'tpg' => {
            'ext'        => 'tpg',
            'mime'    => 'application/tpg',
            'desc'    => 'National Geographic Topo (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tpg -F OUTFILE'
        },
        'tmpro' => {
            'ext'        => 'tmp',
            'mime'    => 'application/tmpro',
            'desc'    => 'TopoMapPro Places (gpsbabel)',
            'spacer' => '',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o tmpro -F OUTFILE'
        },
        'gpsdrive' => {
            'ext'        => 'gpg',
            'mime'    => 'application/gpsdrive',
            'spacer' => '',
            'desc'    => 'GpsDrive (gpsbabel)',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'gpsbabel -i gpx -f INFILE -o gpsdrive -F OUTFILE'
        },

        'cachemate' => {
            'ext'        => 'pdb',
            'mime'    => 'application/cachemate',
            'spacer' => '',
            'desc'    => 'CacheMate for PalmOS (cmconvert)',
            'filter_src'    => 'gpx',
            'filter_exec'    => 'cmconvert -o OUTFILE INFILE'
        }

}
