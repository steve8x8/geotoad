# $Id: output.rb,v 1.20 2002/08/06 11:56:50 strombt Exp $

class Output < Common
	$MAX_NOTES_LEN = 1999
	$DetailURL="http://www.geocaching.com/seek/cache_details.aspx?guid="
	$ReplaceWords = {
		'OF'			=> '',
		'A'				=> '',
		'AND'			=> '',
		'ON'			=> '',
		'CACHE'		=> '',
		'FROM'		=> '',
		'GEOCACHE'	=> '',
		'PARK'		=> 'Pk',
		'THE'			=> '',
		'FOR'			=> '',
		'LAKE'		=> 'Lk',
		'ROAD'		=> 'Rd',
		'RIVER'		=> '',
		'ONE'			=> '1',
		'CREEK'		=> 'Ck',
        'BLACK'     => 'Blk',
		'MOUNTAIN'	=> 'Mt',
		'WITH'		=> 'W',
        'DOUBLE'    => 'Dbl',
        'IS'        => '',
        'THAT'      => 'T',
        'IN'        => '',
        'OVERLOOK'  => 'Ovlk'
	}

	$Format = {
		'gpspoint'	=> {
			'ext'		=> 'gpd',
			'mime'	=> 'application/gpspoint',
			'desc'	=> 'gpspoint datafile',
			'templatePre'	=> "GPSPOINT DATA FILE\ntype=\"fileinfo\"  version=\"1.00\"\n" +
											"type=\"programinfo\" program=\"geotoad\" version=\"0.0\"\n",
			'templateWP'		=> "type=\"waypoint\" latdata=\"<%wp.latdata%>\" londata=\"<%wp.londata%>\"" +
									 		"name=\"<%out.id%>\" comment=\"<%wp.name%>\"" +
											"symbol=\"flag\"  display_option=\"symbol+name\"\n",
		},
		'easygps' => {
			'ext'		=> 'loc',
			'mime'	=> 'application/easygps',
			'desc'	=> 'Geocaching.com .loc XML file',
			'templatePre'	=> "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><loc version=\"1.0\" src=\"EasyGPS\">",
			'templateWP'	=> "<waypoint><name id=\"<%out.id%>\"><![CDATA[<%wp.name%>]]></name>" +
											"<coord lat=\"<%wp.latdata%>\" lon=\"<%wp.londata%>\"/>" +
											"<type>geocache</type><link text=\"Cache Details\"><%out.url%></link></waypoint>",
			'templatePost'	=> '</loc>'
		},
		'html'	=> {
			'ext'		=> 'html',
			'mime'	=> 'text/html',
			'desc'	=> 'Simple HTML table format',
			'spacer'	=> "<br>&nbsp;<br>\n",
			'templatePre' => "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\">\n" +
                "<html><head>\n<title>GeoToad Output</title>\n" +
                "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">\n" + "</head>\n" +
				"<body link=\"#000099\" vlink=\"#000044\" alink=\"#000099\">\n" +
				"GeoToad query: <%out.title%>",
            'templateIndex' => "* <a href=\"#<%out.wid%>\"><%wp.name%></a><br>",
			'templateWP'	=>
				"<hr noshade size=\"1\">\n<a name=\"<%out.wid%>\"></a><font color=\"#000099\"><a href=\"<%out.url%>\"><big><strong><%wp.name%></strong></big></a></font>&nbsp;&nbsp;  <b><%wp.travelbug%></b><br>\n" +
                "<font color=\"#555555\"><strong><%wp.creator%></strong></font>, <%wp.latwritten%> <%wp.lonwritten%><br>" +
				"<font color=\"#339933\"><%wp.type%> D<%wp.difficulty%>/T<%wp.terrain%> - placed: <%wp.cdate%> last: <%wp.mdate%> days ago</font><br>" +
				"<p><%out.details%></p>\n",
			'templatePost'	=> "</body></html>"
		},

		'text'	=> {
			'ext'		=> 'txt',
			'mime'	=> 'text/plain',
			'desc'	=> 	'Plain ASCII',
			'spacer'	=> "\r\n",
			'templatePre' => "GeoToad Output\r\n----------------------------\r\n",
			'templateWP'	=> "== \"<%wp.name%>\" (<%out.wid%>) by <%wp.creator%>\r\n" +
				"Difficulty: <%wp.difficulty%>, Terrain: <%wp.terrain%>\r\n" +
				"Lat: <%wp.latwritten%> Lon: <%wp.lonwritten%>\r\n" +
				"Type: <%wp.type%>, Creation: <%wp.cdate%>, Last found: <%wp.mdate%> days ago\r\n" +
				"Details:\r\n<%out.details%>\r\n\r\n\r\n"
		},

		'csv'	=> {
			'ext'		=> 'csv',
			'mime'	=> 'text/plain',
			'desc'	=> 'CSV for spreadsheet imports',
			'spacer'	=> "",
			'templatePre' => "\"Name\",\"Waypoint ID\",\"Creator\",\"Difficulty\",\"Terrain\"," +
											"\"Latitude\",\"Longitude\",\"Type\",\"Creation Date\", \"Details\"\r\n",
			'templateWP'	=> "\"<%wp.name%>\",\"<%out.wid%>\",\"<%wp.creator%>\"," +
				"<%wp.difficulty%>,<%wp.terrain%>,<%wp.latwritten%>,<%wp.lonwritten%>," +
				"\"<%wp.type%>\",\"<%wp.cdate%>\",\"<%out.details%>\"\r\n"
		},

		'vcf'	=> {
			'ext'						=> 'vcf',
			'mime'					=> 'text/x-vcard',
			'detailsLength'	=> 2000,
			'desc'	=> 'VCF for iPod Contacts export',
			'templatePre'		=> "",
			'templateWP'		=> "BEGIN:vCard\nVERSION:2.1\n" +
				 "FN:G<%out.average%> <%out.sname%>\nN:G<%out.average%>;<%out.sname%>\n" +
				 "NOTE:<%out.details%>\n" +
				 "ADD:<%wp.latwritten%>;<%wp.lonwritten%>;;<%wp.state%>;\n" +
				 "TEL;HOME:<%out.wid%>\nEMAIL;INTERNET:<%wp.difficulty%>@<%wp.terrain%>\n" +
				 "TITLE:<%wp.name%>\nORG:<%wp.type%> <%wp.cdate%>\nEND:vCard\n",
		},

		'gpsman' => {
			'ext'		=> 'gpm',
			'mime'	=> 'application/gpsman',
			'desc'	=> 'GPSman datafile (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o gpsman -F OUTFILE'
		},

		'gpx' => {
			'ext'		=> 'gpx',
			'mime'	=> 'application/gpx',
			'desc'	=> 'GPX XML format (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o gpx -F OUTFILE'
		},

		'mapsend' => {
			'ext'		=> 'mps',
			'mime'	=> 'application/mapsend',
			'desc'	=> 'Magellan MapSend software (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo  -f INFILE -o mapsend -F OUTFILE'
		},

		'pcx' => {
			'ext'		=> 'pcx',
			'mime'	=> 'application/pcx',
			'desc'	=> 'Garmin PCX5 (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o pcx -F OUTFILE'
		},

		'gpsutil' => {
			'ext'		=> 'gpu',
			'mime'	=> 'application/gpsutil',
			'desc'	=> 'gpsutil (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o gpsutil -F OUTFILE'
		},

		'tiger' => {
			'ext'		=> 'tgr',
			'mime'	=> 'application/xtiger',
			'desc'	=> 'U.S. Census Bureau Tiger Mapping Service Data (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o tiger -F OUTFILE'
		},

        'xmap' => {
			'ext'		=> 'tgr',
			'mime'	=> 'application/xmap',
			'desc'	=> 'Delorme Topo USA4/XMap Conduit (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o xmap -F OUTFILE'
		},

        'dna' => {
			'ext'		=> 'dna',
			'mime'	=> 'application/xmap',
			'desc'	=> 'Navitrak DNA marker (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o dna -F OUTFILE'
		},

        'psp' => {
			'ext'		=> 'psp',
			'mime'	=> 'application/psp',
			'desc'	=> 'Microsoft PocketStreets 2002 Pushpin (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o psp -F OUTFILE'
		},

        'cetus' => {
			'ext'		=> 'cet',
			'mime'	=> 'application/cetus',
			'desc'	=> 'Cetus for PalmOS (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o cetus -F OUTFILE'
		},
        'gpspilot' => {
			'ext'		=> 'gps',
			'mime'	=> 'application/gpspilot',
			'desc'	=> 'GPSPilot for PalmOS (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o dna -F OUTFILE'
		},
        'magnav' => {
			'ext'		=> 'mgv',
			'mime'	=> 'application/magnav',
			'desc'	=> 'Magellan NAV Companion for PalmOS (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o magnav -F OUTFILE'
		},
        'mxf' => {
			'ext'		=> 'mxf',
			'mime'	=> 'application/mxf',
			'desc'	=> 'MapTech Exchange (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o mxf -F OUTFILE'
		},
        'holux' => {
			'ext'		=> 'wpo',
			'mime'	=> 'application/holux',
			'desc'	=> 'Holux gm-100  (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o wpo -F OUTFILE'
		},
        'ozi' => {
			'ext'		=> 'ozi',
			'mime'	=> 'application/ozi',
			'desc'	=> 'OziExplorer (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o ozi -F OUTFILE'
		},
        'tpg' => {
			'ext'		=> 'tpg',
			'mime'	=> 'application/tpg',
			'desc'	=> 'National Geographic Topo (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o tpg -F OUTFILE'
		},
        'tmpro' => {
			'ext'		=> 'tmp',
			'mime'	=> 'application/tmpro',
			'desc'	=> 'TopoMapPro Places (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o tmpro -F OUTFILE'
		},
        'gpsdrive' => {
			'ext'		=> 'gpg',
			'mime'	=> 'application/gpsdrive',
			'desc'	=> 'GpsDrive (gpsbabel)',
			'filter_src'	=> 'easygps',
			'filter_exec'	=> 'gpsbabel -i geo -f INFILE -o gpsdrive -F OUTFILE'
		}
	}


	## the functions themselves ####################################################

	def initialize
		@output = Array.new
        @waypointLength = 8
        # autodiscovery of gpsbabel output types if it's found!
	end

	def input(data)
		@wpHash=data
	end

	# converts a geocache name into a much shorter name. This algorithm is
	# very sketchy and needs some real work done to it by a brave volunteer.
	def shortName(name)
		tempname = name.dup
		tempname.gsub!('cache', '')
        # acronym.
        if tempname =~ /(\w)\. (\w)\. (\w)/
            debug "shortname: acronym detected.. removing extraneous dots and spaces"
            tempname.gsub!(/\. /, '')
        end


		tempwords=tempname.split(' ')
		newwords=Array.new

        debug "shortname: making a short name from #{name} (now #{tempname})"

		if tempwords.length == 1		# if there is only one word, use it!
            tempname.gsub!(/\W/, '')
            debug "shortname: only one word in #{tempname}, using it"
			#@wpHash[wid]['sname'] = newwords[0]
			return tempname
        else
            debug "#{tempwords.length} words left in this, processing"
		end

		tempwords.each { |word|
			word.gsub!(/\W/, '')
			testWord = word.tr('[a-z]', '[A-Z]')			# lame way for case insensitive
			if $ReplaceWords[testWord]
                debug "shortname: #{word} is changing to #{$ReplaceWords[testWord]}"
				word = $ReplaceWords[testWord]
			elsif (word.length > 6)
                debug "shortname: word #{word} is still long, stripping vowels"
				word = word[0..0] + word[1..15].gsub(/[AEIOUaeiou]/, '')	# remove vowels
			end
			# if it is STILL >wplength
			if word && (word.length > @waypointLength)
                debug "shortname: cutting #{word} in #{name} to #{@waypointLength - 2} chars"
				word.slice!(0,(@waypointLength - 2))
			end

			if word
				newwords.push(word)
			end
		}

        debug "shortname: final result is #{newwords[0..4].to_s}"
		newwords[0..4].to_s
	end

	# select the format for the next set of output
	def formatType=(format)
		if ($Format[format])
			@outputFormat = $Format[format]
			@outputType = format
			debug "format switched to #{format}"
		else
			puts "[*] Attempted to select invalid format: #{format}"
			return nil
		end
	end

    def waypointLength=(length)
        @waypointLength=length
        debug "set waypoint id length to #{@waypointLength}"
    end

	# exploratory functions.
	def formatList
		formatList = Array.new
		$Format.each_key { |format|
			formatList.push(format)
		}
		formatList
	end


	def formatExtension(format)
		return $Format[format]['ext']
	end

	def formatMIME(format)
		return $Format[format]['mime']
	end

	def formatDesc(format)
		return $Format[format]['desc']
	end


	## sets up for the filtering process ################3
	def prepare (title)
		# if we are not actually generating the output, lets do it in a meta-fashion.
		debug "preparing for #{@outputType}"
		if (@outputFormat['filter_exec'])
			oldformat = @outputType
			src = @outputFormat['filter_src']
			exec = @outputFormat['filter_exec']
			formatSelect(src)
			@output = filterInternal(title)
			formatSelect(oldformat)
		else
			@output = filterInternal(title)
		end
		return @output
	end

	def writeFile (file)
			file = open(file, "w");
			file.puts(@output)
			file.close
	end

	# writes the output to a file or to a program #############################
	def commit (file)
		debug "committing #{@outputType}"
		if @outputFormat['filter_exec']
			exec = @outputFormat['filter_exec']
			tmpfile = $TEMP_DIR + "/" + @outputType + "." + rand(500000).to_s
			exec.gsub!('INFILE', tmpfile)
			exec.gsub!('OUTFILE', file)
			writeFile(tmpfile)
			if (File.exists?(file))
				File.unlink(file)
			end

			debug "exec = #{exec}"
			system(exec)
			if (! File.exists?(file))
				puts "[*] ERROR! Output filter did not create file #{file}. exec was:"
				puts "[*]        #{exec}"
			end
		else
			debug "no exec"
			writeFile(file)
		end
	end

	def filterInternal (title)
		debug "generating output with output: #{@outputType} - #{$Format[@outputType]['desc']}"
		output = @outputFormat['templatePre'].dup
		outVars = Hash.new
        wpList = Hash.new
        outVars['title'] = title


        @wpHash.each_key { |wid|
            wpList[wid] = @wpHash[wid]['name'].dup
            #puts "made list with #{wid} = #{wpList[wid]}"
        }

        # somewhat lame.. HTML specific index that really needs to be in the templates, but I need
        # this done before I go geocaching in 45 minutes.

        if @outputType == "html"
            htmlIndex=''
            debug "I should generate an index, I'm html"


            wpList.sort{|a,b| a[1]<=>b[1]}.each {  |wpArray|
                wid = wpArray[0]
                @wpHash[wid]['details'].gsub!(/\&([A-Z])/, '&amp;(#{$1})');
                @wpHash[wid]['creator'].gsub!('&', '&amp;');
                htmlIndex = htmlIndex + "<li><a href=\"\##{wid}\">#{@wpHash[wid]['name']}</a>"

                if (@wpHash[wid]['travelbug'])
                    htmlIndex = htmlIndex + " [TB]"
                end

                debug "Creating index for \"#{@wpHash[wid]['name']}\" (#{wid})"
                if (@wpHash[wid]['mdate'] < 0)
                    htmlIndex = htmlIndex + " (v)"
                    debug "Marking #{@wpHash[wid]['name']} a virgin (#{@wpHash[wid]['mdate']})"
                end
                htmlIndex = htmlIndex + "</li>\n"
            }

            output = output + "<ul>\n" + htmlIndex + "</ul>\n"
        end

        wpList.sort{|a,b| a[1]<=>b[1]}.each {  |wpArray|
            wid = wpArray[0]
			detailsLen = @outputFormat['detailsLength'] || 20000

			numEntries = @wpHash[wid]['details'].length / detailsLen

			outVars['wid'] = wid.dup
            outVars['sname'] = shortName(@wpHash[wid]['name'])[0..14]
            debug "my sname is #{outVars['sname']}"
            if (outVars['sname'].length < 1)
                puts "#{wid}: #{@wpHash[wid]['name']} did not get an sname returned. BUG!"
                exit 2
            end

            # well, this is crap.
            outVars['id'] = outVars['sname'][0..(@waypointLength - 1)].upcase
            outVars['title']="XXXX"
            debug "my id is #{outVars['id']}"

            if (outVars['id'].length < 1)
                debug "our id is no good, using the wid"
                puts "warning: We could not make an id from \"#{outVars['sname']}\" so we are using #{wid}"
                outVars['id'] = wid.dup
            end
			outVars['url'] = $DetailURL + @wpHash[wid]['sid'].to_s
            if (! @wpHash[wid]['terrain'])
                puts "[*] Error: no terrain found"
                @wpHash[wid].each_key { |key|
                    puts "#{key} = #{@wpHash[wid][key]}"
                }
                exit
            end
            if (! @wpHash[wid]['difficulty'])
                puts "[*] Error: no difficulty found"
                exit
            end
			outVars['average'] = (@wpHash[wid]['terrain'] + @wpHash[wid]['difficulty'] / 2).to_i

			# this crazy mess is all due to iPod's VCF reader only supporting 2k chars!
			0.upto(numEntries) { |entry|
				if (entry > 0)
					outVars['sname'] = shortName(@wpHash[wid]['name'])[0..12] << ":" << (entry + 1).to_s
				end

				detailByteStart = entry * detailsLen
        detailByteEnd = detailByteStart + detailsLen - 1
				outVars['details'] = @wpHash[wid]['details'][detailByteStart..detailByteEnd]
				if (@outputFormat['spacer'])
					outVars['details'].gsub!(/\*/, @outputFormat['spacer'])
				end

				tempOutput = @outputFormat['templateWP'].dup

				# okay. I will fully admit this is a *very* unusual way to handle
				# the templates. This all came to be due to a lot of debugging.

                # ** PLEASE MOVE INTO ANOTHER SUBROUTINE! THIS IS STUPID! **
				tags = tempOutput.scan(/\<%(\w+\.\w+)%\>/)

				tags.each { |tag|
					(type, var) = tag[0].split('.')
					#puts "#{tag} - type: #{type} var: #{var}"
					if (type == "wp")
						tempOutput.gsub!(/\<%wp\.#{var}%\>/, @wpHash[wid][var].to_s)
					elsif (type == "out")
						tempOutput.gsub!(/\<%out\.#{var}%\>/, outVars[var].to_s)
					else
						puts "unknown type: #{type} tag=#{var}"
					end
				}
				output << tempOutput
			}
		}
		if @outputFormat['templatePost']
			output << @outputFormat['templatePost']
		end

		return output
	end
end

