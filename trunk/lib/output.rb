# $Id$
require 'cgi'
require 'lib/templates'

class Output
  include Common
  include Messages

  $MAX_NOTES_LEN = 1999
  $ReplaceWords = {
    'OF'			=> '',
    'A'				=> '',
    'AND'			=> '',
    'ON'			=> '',
    'CACHE'		=> '',
    'FROM'		=> '',
    'GEOCACHE'	=> '',
    'MISSION'   => 'Msn',
    'PARK'		=> 'Pk',
    'IMPOSSIBLE' => 'Imp',
    'THE'			=> '',
    'FOR'			=> '',
    'LAKE'		=> 'Lk',
    'ROAD'		=> 'Rd',
    'RIVER'		=> '',
    'ONE'		=> '1',
    'TWO'       => '2',
    'THREE'     => '3',
    'FOUR'      => '4',
    'FIVE'      => '5',
    'SIX'       => '6',
    'SEVEN'     => '7',
    'EIGHT'     => '8',
    'NINE'      => '9',
    'TEN'       => '10',
    'CREEK'		=> 'Ck',
    'LITTLE'    => 'Lil',
    'BLACK'     => 'Blk',
    'LOOP'      => 'Lp',
    'TRAIL'     => 'Tr',
    'EITHER'    => 'E',
    'BROWN'     => 'Brn',
    'ORANGE'    => 'Org',
    'MOUNTAIN'	=> 'Mt',
    'COUNTY'    => 'Cty',
    'WITH'		=> 'W',
    'DOUBLE'    => 'Dbl',
    'IS'        => '',
    'THAT'      => 'T',
    'IN'        => '',
    'OVERLOOK'  => 'Ovlk',
    'Ridge'     => 'Rdg',
    'Forest'    => 'Frst',
    'II'        => '2',
    'III'       => '3',
    'IV'        => '4',
    'BY'        => '',
    'HOTEL'     => 'Htl',
    'MOTEL'     => 'Mtl',

    # German Words Follow
    'DIE'       => '',
    'DER'       => '',
    'DEN'       => '',
    'ZUM'       => '',
    'IM'        => '',
    'EIN'       => '',
    'DAS'       => ''
  }

  ## the functions themselves ####################################################

  def initialize
    @output = Array.new
    @waypointLength = 0
  end

  def input(data)
    @wpHash=data
  end

  # converts a geocache name into a much shorter name. This algorithm is
  # very sketchy and needs some real work done to it by a brave volunteer.
  def shortName(name)
    tempname = name.dup
    tempname.gsub!('cache', '')
    # not sure why this isn't being handled by the \W regexps, but
    # I'm taking care of it to fix a bug with caches with _ in their name.

    tempname.gsub!(/_/, '')

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
      @outputFormat = $Format[format].dup
      @outputType = format
      debug "format switched to #{format}"
    else
      displayError "[*] Attempted to select invalid format: #{format}"
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

  def formatRequirement(format)
    return $Format[format]['required']
  end

  ## sets up for the filtering process ################3
  def prepare (title)
    @title = title

    # if we are not actually generating the output, lets do it in a meta-fashion.
    debug "preparing for #{@outputType}"
    if (@outputFormat['filter_exec'])
      post_format = @outputType
      debug "pre-formatting as #{@outputFormat['filter_src']} (from #{post_format})"
      self.formatType=@outputFormat['filter_src']
      debug "pre-format: #{@outputFormat['desc']}"
      @output = filterInternal(title)
      self.formatType=post_format
      debug "post-format: #{@outputFormat['desc']} via #{@outputFormat['filter_exec']}"
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
    debug "committing file type #{@outputType} to #{file}"
    if @outputFormat['filter_exec']
      displayMessage "Executing #{@outputFormat['filter_exec']}"
      exec = @outputFormat['filter_exec'].dup
      tmpfile = $CACHE_DIR + "/" + @outputType + "." + rand(500000).to_s
      exec.gsub!('INFILE', "\"#{tmpfile}\"")
      exec.gsub!('OUTFILE', "\"#{file}\"")
      writeFile(tmpfile)
      if (File.exists?(file))
        File.unlink(file)
      end

      debug "exec = #{exec}"
      system(exec)
      if (! File.exists?(file))
        displayError "Output filter did not create file #{file}. exec was:"
        displayError "#{exec}"
      end
    else
      debug "no exec"
      writeFile(file)
    end
  end

  def replaceVariables(templateText)
    # okay. I will fully admit this is a *very* unusual way to handle
    # the templates. This all came to be due to a lot of debugging.
    debug "out.wid for #{@currentWid} is [#{@outVars['wid']}]"

    tags = templateText.scan(/\<%(\w+\.\w+)%\>/)
    text = templateText.dup
    tags.each { |tag|
      (type, var) = tag[0].split('.')
      value = 'UNKNOWN_TAG'
      if (type == "wp")
        value = @wpHash[@currentWid][var].to_s
      elsif (type == "out")
        value = @outVars[var].to_s
      elsif (type == "wpEntity")
        value = makeXML(@wpHash[@currentWid][var].to_s)
      elsif (type == "outEntity")
        value = makeXML(@outVars[var].to_s)
      elsif (type == "wpText")
        value = makeText(@wpHash[@currentWid][var].to_s)
      elsif (type == "outText")
        value = makeText(@outVars[var].to_s)
      end
      debug "TAG <%#{tag}%> for #{@currentWid} -> #{value}"

      # This looks very ugly, but it works around backreference issues. Thanks ddollar!
      text.gsub!('<%' + tag[0] + '%>') { value }
    }

    debug "Replaced text: #{text}"
    return text
  end

  def makeXML(str)
    if not str or str.length == 0
        return str
    end

    text = CGI.escapeHTML(str)
    # CGI.escapeHTML will try to re-escape previously escaped entities.
    # Fix numerical entities such as Pateniemen l&amp;#228;mp&amp;#246;keskus
    text.gsub!(/&amp;([\#\d][\d]+;)/, "&\\1")
    # XML only pre-defines the following named character entities:
    text.gsub!('&amp;(amp;)', "&\\1")

    # There is also [lg]t; &quot; &apos;, but they seem to be handled properly.

    # From http://snippets.dzone.com/posts/show/1161
    str.unpack("U*").collect {|s| (s > 127 ? "&##{s};" : s.chr) }.join("")
     

    # Fix apostrophes so that they show up as expected. Fixes issue 26.
    text.gsub!('&#8217;', "'")
    if text != str
      debug "makeXML: %s" % text
    end
    return text
  end

  def makeText(str)
    # Take HTML-like input, no matter how hacked up, and turn it into text
    text = CGI.unescapeHTML(str)

    # rip some tags out.
    text.gsub!(/\<\/li\>/i, '')
    text.gsub!(/\<\/p\>/i, '')
    text.gsub!(/<\/*i\>/i, '')
    text.gsub!(/<\/*body\>/i, '')
    text.gsub!(/<\/*option.*?\>/i, '')
    text.gsub!(/<\/*select.*?\>/i, '')
    text.gsub!(/<\/*span.*?\>/i, '')
    text.gsub!(/<\/*font.*?\>/i, '')
    text.gsub!(/<\/*ul\>/i, '')
    text.gsub!(/style=\".*?\"/i, '')

    # substitute
    text.gsub!(/\<p\>/i, "\n\n")
    text.gsub!(/\<li\>/i, "\n * (o) ")
    text.gsub!(/<\/*b>/i, '')
    text.gsub!(/\<img.*?\>/i, '[img]')
    text.gsub!(/\<.*?\>/m, ' *')
    text.gsub!(/\&nbsp\;/, ' ')
    text.gsub!(/\&rsquo\;/, "'")
    text.gsub!(/\&ndash;/, " - ")
    text.gsub!(/\&deg;/, "'")

    # combine all the tags we nuked. These regexps
    # could probably be cleaned up pretty well.
    text.gsub!(/\*[\s\*]+/m, "* ")
    text.gsub!(/\*/, "\n* ")
    text.gsub!(/[\x01-\x1F]/, '')      # low ascii

    # kill the last space, which makes the CSV output nicer.
    text.gsub!(/ $/, '')
    return text
  end

  def filterInternal (title)
    debug "generating output: #{@outputType} - #{$Format[@outputType]['desc']}"
    @outVars = Hash.new
    wpList = Hash.new
    @outVars['title'] = title
    @currentWid = 0
    # output is what we generate. We start with the templates pre.
    output = replaceVariables(@outputFormat['templatePre'])
    @outVars['counter'] = 0


    # this is a strange maintenance loop of sorts. First it builds a list, which
    # I'm not sure what it's used for. Second, it inserts a new item named "sname"
    # which is the caches short name or geocache name.

    @wpHash.each_key { |wid|
      if (! @wpHash[wid]['name'])
        displayError "#{wid} has no name, what gives?"
        exit
      end

      wpList[wid] = @wpHash[wid]['name'].dup

      if @waypointLength > 1
        sname = shortName(@wpHash[wid]['name'])

        # This loop checks for any other caches with the same generated waypoint id
        # If a conflict is found, it looks for the unique characters in them, and
        # puts something nice together.
        @wpHash.each_key { |conflictWid|
          if (@wpHash[conflictWid]['sname']) && (@wpHash[conflictWid]['sname'][0..7] == sname[0..7])
            debug "Conflict found with #{sname} and #{@wpHash[conflictWid]['snameUncut']}"
            # Get the first 3 characters
            unique = ''
            x = 0

            # and then the unique ones after that
            sname.split('').each { |ch|
              if sname[x] != @wpHash[conflictWid]['snameUncut'][x]
                unique = unique + sname[x].chr
                #puts "unique: #{sname[x].chr} does not match #{@wpHash[conflictWid]['sname'][x].chr}"
              end
              x = x + 1
            }

            if unique.length > 6
              sname = sname[0..3] + unique
            else
              sname = sname[0..(7-unique.length)] + unique
            end

            debug "Conflict resolved with short name: #{sname} (unique = #{unique})"
          end
        }
        @wpHash[wid]['sname'] = sname[0..(@waypointLength - 1)]
        @wpHash[wid]['snameUncut'] = sname
      elsif @waypointLength == -1
        # full text names.. useful for Google Earth
        @wpHash[wid]['sname'] = @wpHash[wid]['name']
      else
        # use waypoint id
        @wpHash[wid]['sname'] = wid.dup
      end
    }


    # ** This will be removed for GeoToad 4.0, when we use a real templating engine that can do loops **
    if @outputType == "html" || @outputType == "html-decrypt"
      htmlIndex=''
      debug "I should generate an index, I'm html"
      symbols = Hash.new

      wpList.sort{|a,b| a[1]<=>b[1]}.each {  |wpArray|
        wid = wpArray[0]
        debug "Creating index for \"#{@wpHash[wid]['name']}\" (#{wid})"

        htmlIndex = htmlIndex + "<li>"
        symbols[wid] = ''

        if (@wpHash[wid]['travelbug'])
          symbols[wid] = "<b><font color=\"#11CC11\">&euro;</font></b>"
        end

        if (@wpHash[wid]['terrain'] > 3)
          symbols[wid] =  symbols[wid] + "<b><font color=\"#999922\">&sect;</font></b>"
        end

        if (@wpHash[wid]['funfactor'] >= 2.5)
          symbols[wid] =  symbols[wid] + "<b><font color=\"#BB2222\">&hearts;</font></b>"
        elsif (@wpHash[wid]['funfactor'] >= 1.5)
          symbols[wid] =  symbols[wid] + "<b><font color=\"#BB9999\">&hearts;</font></b>"
        end

        if (@wpHash[wid]['difficulty'] > 3)
          symbols[wid] =  symbols[wid] + "<b><font color=\"#440000\">&uarr;</font></b>"
        end

        if (@wpHash[wid]['mdays'] < 0)
          symbols[wid] =  symbols[wid] + "<b><font color=\"#9900CC\">&infin;</font></b>"
        end

        if (symbols[wid].length < 1)
          symbols[wid] = "&nbsp;"
        end

        htmlIndex = htmlIndex + symbols[wid]

        # make the names bold if they are virgins. Broken when we moved everything into symbols.
        if (@wpHash[wid]['mdays'] < 0)
          htmlIndex = htmlIndex + "<b>"
        end

        htmlIndex = htmlIndex + "<a href=\"\##{wid}\">#{@wpHash[wid]['name']}</a>"

        if (@wpHash[wid]['mdays'] < 0)
          htmlIndex = htmlIndex + "</b>"
        end

        htmlIndex = htmlIndex + " <font color=\"#444444\">(#{@wpHash[wid]['sname']})</font></li>\n"
      }

      output = output + "<ul>\n" + htmlIndex + "</ul>\n"
    end



    wpList.sort{|a,b| a[1]<=>b[1]}.each {  |wpArray|
      @currentWid = wpArray[0]
      debug "--- Output loop: #{@currentWid} - #{@wpHash[@currentWid]['name']} by #{@wpHash[@currentWid]['creator']}"
      detailsLen = @outputFormat['detailsLength'] || 20000
      numEntries = @wpHash[@currentWid]['details'].length / detailsLen

      @outVars['wid']     = @currentWid.dup
      if symbols
        @outVars['symbols'] = symbols[@currentWid]
      end
      @outVars['id']      = @wpHash[@currentWid]['sname'].dup
      # This should clear out the hint-dup issue that Scott Brynen mentioned.
      @outVars['hint']    = ''

      @outVars['mdate'] = @wpHash[@currentWid]['mtime'].strftime("%Y-%m-%d")
      @outVars['cdate'] = @wpHash[@currentWid]['ctime'].strftime("%Y-%m-%d")

      # For GPX
      @outVars['XMLDate'] = @wpHash[@currentWid]['ctime'].strftime("%Y-%m-%dT%H:00:00.0000000-07:00")

      # for some templates, we pad.
      @outVars['latdatapad5'] = sprintf("%2.5f", @wpHash[@currentWid]['latdata'])
      @outVars['londatapad5'] = sprintf("%2.5f", @wpHash[@currentWid]['londata'])
      @outVars['latdatapad6'] = sprintf("%2.6f", @wpHash[@currentWid]['latdata'])
      @outVars['londatapad6'] = sprintf("%2.6f", @wpHash[@currentWid]['londata'])

      if @wpHash[@currentWid]['distance']
        @outVars['relativedistance'] = 'Distance: ' + @wpHash[@currentWid]['distance'].to_s + 'mi ' + @wpHash[@currentWid]['direction']
      end

      if @wpHash[@currentWid]['state']
        @outVars['location'] = @wpHash[@currentWid]['state'] + ', ' + @wpHash[@currentWid]['country']
      else
        @outVars['location'] = @wpHash[@currentWid]['country']
      end

      # fix for bug reported by wkraml%a1.net - caches with no hint get the last hint.
      @outVars['hintdecrypt'] = nil

      if @wpHash[@currentWid]['hint'] && @wpHash[@currentWid]['hint'].length > 0
        hint = @wpHash[@currentWid]['hint']
        @outVars['hint'] = 'Hint: ' + hint
        @outVars['hintdecrypt'] = 'Hint: ' + hint.tr('A-MN-Z', 'N-ZA-M').tr('a-mn-z', 'n-za-m')
        debug "Hint: [#{@outVars['hint']}]"
        debug "Decrypted hint: [#{@outVars['hintdecrypt']}]"
      end


      if (@outVars['id'].length < 1)
        debug "our id is no good, using the wid"
        displayWarning "We could not make an id from \"#{@outVars['sname']}\" so we are using #{@currentWid}"
        @outVars['id'] = @currentWid.dup
      end
      @outVars['url'] =  @wpHash[@currentWid]['url']

      if (! @wpHash[@currentWid]['terrain'])
        displayError "[*] Error: no terrain found for #{@currentWid}"
        @wpHash[@currentWid].each_key { |key|
          displayError "#{key} = #{@wpHash[@currentWid][key]}"
        }
        exit
      end
      if (! @wpHash[@currentWid]['difficulty'])
        displayError "[*] Error: no difficulty found"

        exit
      end
      @outVars['average'] = (@wpHash[@currentWid]['terrain'] + @wpHash[@currentWid]['difficulty'] / 2).to_i

      # This comment is only here to make ArmedBear-J parse the ruby properly: /\*/, "[SPACER]");


      # ** This will be removed for GeoToad 4.0, when we use a real templating engine that can do loops **
      if @outputType == 'gpx'
        @outVars['gpxlogs'] = ''
        0.upto(4) { |x|
          debug "Looking for comment #{x}"
          if @wpHash[@currentWid]["comment#{x}Type"]
            rawcomment =
              "    <groundspeak:log id=\"<%wpEntity.comment#{x}ID%>\">\r\n" +
              "      <groundspeak:date><%wpEntity.comment#{x}Date%></groundspeak:date>\r\n" +
              "      <groundspeak:type><%wpEntity.comment#{x}Type%></groundspeak:type>\r\n" +
              "      <groundspeak:finder id=\"<%wpEntity.comment#{x}UID%>\"><%wpEntity.comment#{x}Name%></groundspeak:finder>\r\n" +
              "      <groundspeak:text encoded=\"False\"><%wpEntity.comment#{x}Comment%></groundspeak:text>\r\n" +
              "    </groundspeak:log>\r\n"
            @outVars['gpxlogs'] = @outVars['gpxlogs'] + replaceVariables(rawcomment)
          end
        }
      end

      @outVars['counter'] = @outVars['counter'] + 1

      # this crazy mess is all due to iPod's VCF reader only supporting 2k chars!
      0.upto(numEntries) { |entry|
        if (entry > 0)
          @outVars['sname'] = shortName(@wpHash[@currentWid]['name'])[0..12] << ":" << (entry + 1).to_s
        end

        detailByteStart = entry * detailsLen
        detailByteEnd = detailByteStart + detailsLen - 1
        @outVars['details'] = @wpHash[@currentWid]['details'][detailByteStart..detailByteEnd]

        # a bad hack.
        @outVars['details'].gsub!(/\*/, "[SPACER]");
        tempOutput = replaceVariables(@outputFormat['templateWP'])

        # we move this to after our escapeHTML's so the HTML in here doesn't get
        # encoded itself! I think it should be handled a little better than this.
        if (tempOutput)
          output << tempOutput.gsub(/\[SPACER\]/, @outputFormat['spacer']);
        end
      }
    }

    if @outputFormat['templatePost']
      output << replaceVariables(@outputFormat['templatePost'])
    end

    return output
  end
end
