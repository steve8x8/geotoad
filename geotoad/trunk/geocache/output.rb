# $Id: output.rb,v 1.20 2002/08/06 11:56:50 strombt Exp $
require 'cgi'
require 'geocache/templates'

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
            # this should use formatType()
            @outputFormat = $Format[src]
            debug "pre-formatting as #{@outputFormat['desc']}"
			@output = filterInternal(title)
			@outputFormat = $Format[oldformat]
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
		debug "committing file type #{@outputType}"
		if @outputFormat['filter_exec']
            puts "[-] Executing #{@outputFormat['filter_exec']}"
			exec = @outputFormat['filter_exec']
			tmpfile = $TEMP_DIR + "/" + @outputType + "." + rand(500000).to_s
			exec.gsub!('INFILE', "\"#{tmpfile}\"")
			exec.gsub!('OUTFILE', "\"#{file}\"")
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
                debug "Creating index for \"#{@wpHash[wid]['name']}\" (#{wid})"

                @wpHash[wid]['details'].gsub!(/\&([A-Z])/, '&amp;(#{$1})');
                htmlIndex = htmlIndex + "<li><a href=\"\##{wid}\">#{@wpHash[wid]['name']}</a>"

                if (@wpHash[wid]['travelbug'])
                    htmlIndex = htmlIndex + " [TB]"
                end

                if (@wpHash[wid]['mdays'] < 0)
                    htmlIndex = htmlIndex + " (v)"
                    debug "Marking #{@wpHash[wid]['name']} a virgin (#{@wpHash[wid]['mdays']})"
                end
                htmlIndex = htmlIndex + "</li>\n"
            }

            output = output + "<ul>\n" + htmlIndex + "</ul>\n"
        end

        wpList.sort{|a,b| a[1]<=>b[1]}.each {  |wpArray|
            wid = wpArray[0]
            debug "Output loop: #{wid} - #{@wpHash[wid]['name']}"
			detailsLen = @outputFormat['detailsLength'] || 20000

			numEntries = @wpHash[wid]['details'].length / detailsLen

			outVars['wid'] = wid.dup
            if @wpHash[wid]['distance']
                outVars['relativedistance'] = 'Distance: ' + @wpHash[wid]['distance'].to_s + 'mi ' + @wpHash[wid]['direction']
            end

            if @wpHash[wid]['hint']
                outVars['hint'] = 'Hint: ' + @wpHash[wid]['hint']
                debug "I will include the hint: #{outVars['hint']}"
            end

            outVars['sname'] = shortName(@wpHash[wid]['name'])[0..14]
            debug "my sname is #{outVars['sname']}"
            if (outVars['sname'].length < 1)
                puts "#{wid}: #{@wpHash[wid]['name']} did not get an sname returned. BUG!"
                exit 2
            end
            # well, this is crap.
            outVars['id'] = outVars['sname'][0..(@waypointLength - 1)]  # lets not .upcase
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

                # a bad hack.
                outVars['details'].gsub!(/\*/, "[SPACER]");

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
					elsif (type == "wpEntity")
						tempOutput.gsub!(/\<%wpEntity\.#{var}%\>/, CGI.escapeHTML(@wpHash[wid][var].to_s))
					elsif (type == "outEntity")
						tempOutput.gsub!(/\<%outEntity\.#{var}%\>/, CGI.escapeHTML(outVars[var].to_s))
                    else
						puts "unknown type: #{type} tag=#{var}"
					end
				}
                # we move this to after our escapeHTML's so the HTML in here doesn't get
                # encoded itself!
                if (tempOutput)
                    output << tempOutput.gsub(/\[SPACER\]/, @outputFormat['spacer']);
                end
			}
		}
		if @outputFormat['templatePost']
			output << @outputFormat['templatePost']
		end

		return output
	end
end

