# $Id$
require 'cgi'
require 'lib/templates'
require 'lib/version'
require 'zlib'

GOOGLE_MAPS_URL = 'http://maps.google.com/maps'

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
    @username = nil
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
      #cache['sname'] = newwords[0]
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
        word = word[0..@waypointLength-2]
      end

      if word
        newwords.push(word)
      end
    }

    debug "shortname: final result is #{newwords[0..8].to_s}"
    newwords[0..8].to_s
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
  def prepare (title, username)
    @title = title
    @username = username

    # if we are not actually generating the output, lets do it in a meta-fashion.
    debug "preparing for #{@outputType}"
    if @outputFormat['filter_exec']
      post_format = @outputType
      debug "pre-formatting as #{@outputFormat['filter_src']} (from #{post_format})"
      self.formatType=@outputFormat['filter_src']
      debug "pre-format: #{@outputFormat['desc']}"
      @output = generateOutput(title)
      self.formatType = post_format
      debug "post-format: #{@outputFormat['desc']} via #{@outputFormat['filter_exec']}"
    else
      @output = generateOutput(title)
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

  def replaceVariables(templateText, wid)
    # okay. I will fully admit this is a *very* unusual way to handle
    # the templates. This all came to be due to a lot of debugging.
    debug "out.wid for #{wid} is [#{@outVars['wid']}]"
    tags = templateText.scan(/\<%(\w+\.\w+)%\>/)
    text = templateText.dup
    tags.each { |tag|
      (type, var) = tag[0].split('.')
      value = 'UNKNOWN_TAG'
      if (type == "wp")
        value = @wpHash[wid][var].to_s
      elsif (type == "out")
        value = @outVars[var].to_s
      elsif (type == "wpEntity")
        value = makeXML(@wpHash[wid][var].to_s)
      elsif (type == "outEntity")
        value = makeXML(@outVars[var].to_s)
      elsif (type == "wpText")
        value = makeText(@wpHash[wid][var].to_s)
      elsif (type == "outText")
        value = makeText(@outVars[var].to_s)
      end
      debug "TAG <%#{tag}%> for #{wid} -> #{value}"

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
    # Fix hex entities too
    #text.gsub!(/&amp;#x([0-9a-fA-F]+);/) { "&\##{$1.to_i(16)")
    text.gsub!(/&amp;(\#x[0-9a-fA-F][0-9a-fA-F]+;)/, "&\\1")

    # XML only pre-defines the following named character entities:
    text.gsub!(/\&amp;(amp;)/, "&\\1")
    text.gsub!(/\&amp;([lg]t;)/, "&\\1")
    text.gsub!(/\&amp;(quot;)/, "&\\1")
    text.gsub!(/\&amp;(apos;)/, "&\\1")

    # From http://snippets.dzone.com/posts/show/1161
    str.unpack("U*").collect {|s| (s > 127 ? "&##{s};" : s.chr) }.join("")

    # Collapse white space
    text.gsub!(/\&(amp;)*nbsp;/, ' ')
    text.gsub!(/[\x09\x0a\x0d]/, ' ')
    text.gsub!(/ +/, ' ')
    # Strip out control characters
    text.gsub!(/[\x00-\x1f]/, '?')
    text.gsub!(/\x7f/, '?')

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
    text.gsub!(/\&quot\;/, '"')
    text.gsub!(/\&apos\;/, "'")
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

  def generatePreOutput(title)
    output = replaceVariables(@outputFormat['templatePre'], nil)
  end

  def updateShortNames()
    snames = {}
    @wpHash.each_key { |wid|
      cache = @wpHash[wid]
      if @waypointLength > 1
        shorter_name = shortName(cache['name'])
        shortest_name = shorter_name[0..(@waypointLength - 1)]
        # If we have two caches that generate the same short name
        if snames.has_key?(shortest_name.upcase)
          other_wid = snames[shortest_name.upcase]
          other_cache = @wpHash[other_wid]
          debug "Conflict found with #{shortest_name} (#{wid} vs #{other_wid})"
          unique_chars = ''
          debug "Conflict resolution using #{shorter_name} and #{other_cache['snameUncut']}"
          0.upto(shorter_name.length-1) { |x|
            if shorter_name[x] != other_cache['snameUncut'][x]
              unique_chars << shorter_name[x].chr
            end
          }
          debug "short name unique chars: #{unique_chars}"
          shortest_name = shorter_name[0..(@waypointLength - 4)] + unique_chars[0..3]
          displayMessage "Resolved short-name conflict for #{wid} (#{shortest_name}) and #{other_wid} (#{other_cache['sname']})"
        end

        snames[shortest_name.upcase] = wid
        cache['sname'] = shortest_name
        cache['snameUncut'] = shorter_name
      # Full length short-name
      elsif @waypointLength == -1
        cache['sname'] = @wpHash[wid]['name']
      else
        cache['sname'] = wid.dup
      end
    }
  end

  def generateHtmlIndex()
    # Returns an index and a hash of wid -> symbol list
    index = '<ul>'
    symbolHash = Hash.new

    @wpHash.keys.sort.each { |wid|
      cache = @wpHash[wid]
      symbolHash[wid] = ''
      if (@wpHash[wid]['travelbug'])
        symbolHash[wid] = "<b><font color=\"#11CC11\">&euro;</font></b>"
      end

      if (@wpHash[wid]['terrain'] >= 3.5)
        symbolHash[wid] << "<b><font color=\"#999922\">&sect;</font></b>"
      end

      if @wpHash[wid]['funfactor']
        if @wpHash[wid]['funfactor'] >= 3.5
          symbolHash[wid] << "<b><font color=\"#BB6666\">&hearts;</font></b>"
        end
      end

      if (@wpHash[wid]['difficulty'] >= 3)
        symbolHash[wid] << "<b><font color=\"#440000\">&uarr;</font></b>"
      end

      if (@wpHash[wid]['mdays'] < 0)
        symbolHash[wid] << "<b><font color=\"#9900CC\">&infin;</font></b>"
      end

      index_item = "<li>#{symbolHash[wid]}"
      if @wpHash[wid]['mdays'] < 0
        index_item << '<strong>'
      end

      index_item << "<a href=\"\##{wid}\">#{cache['name']}</a>"
      if @wpHash[wid]['mdays'] < 0
        index_item << '</strong>'
      end

      index_item << " <font color=\"#444444\">(#{cache['sname']})</font></li>\n"
      index << index_item
    }
    index << '</ul>'
    return [index, symbolHash]
  end

  def createGpxCommentLogs(cache)
    if not cache['comments']
      debug "No comments found for #{cache['name']}"
      return nil
    end

    entries = []
    debug "Generating comment XML for #{cache['name']}"
    cache['comments'].each { |comment|
      comment_id = Zlib.crc32(comment['text'])
      debug "Comment ID: #{comment_id} by #{comment['user']}: #{comment['text']}"
      formatted_date = comment['date'].strftime("%Y-%m-%dT%H:00:00.0000000-07:00")
      entry = ''
      entry << "    <groundspeak:log id=\"#{comment_id}\">\r\n"
      entry << "      <groundspeak:date>#{formatted_date}</groundspeak:date>\r\n"
      entry << "      <groundspeak:type>#{comment['type']}</groundspeak:type>\r\n"
      entry << "      <groundspeak:finder id=\"#{comment['user_id']}\">#{comment['user']}</groundspeak:finder>\r\n"
      entry << "      <groundspeak:text encoded=\"False\">" + makeXML(comment['text']) + "</groundspeak:text>\r\n"
      entry << "    </groundspeak:log>\r\n"
      entries << entry
    }
    debug "Finished generating comment XML for #{cache['name']}"
    debug "Comment Data: #{entries}"
    debug "Comment Data Length: #{entries.length}"
    return entries.join('')
  end

  def decryptHint(hint)
    if hint
      decrypted = hint.tr('A-MN-Z', 'N-ZA-M').tr('a-mn-z', 'n-za-m')
      # Oops, we don't need to decrypt the text within brackets - it's raw.
      decrypted.gsub!(/(\[.*?\])/) { $1.tr('A-MN-Z', 'N-ZA-M').tr('a-mn-z', 'n-za-m') }
      return decrypted
    else
      return ''
    end
  end

  # convert cache "waypoint ID" (GC.....) to numeric value
  def cacheID(wid)
    if wid
      wp = wid.gsub(/^GC/, '')
      if wp.length <= 4 && wp < 'G000'
        # base 16 is easy
        return wp.to_i(16)
      else
        # base 31: consider gaps in char set, and correction offset
        # magic number -411120 reflects that GCG000 = GCFFFF + 1
        return wp.upcase.tr('0-9A-HJKMNPQRTV-Z', '0-9A-U').to_i(31) - 411120
      end
    else
      return 0
    end
  end

  # reduce HTML content (of waypoint table) to a minimum
  # suited for GPSr and parsing in toWptList()
  def reduceHtml(text)
    if !text
      return nil
    end
    # un-fix spaces
    new_text = text.gsub(/\s*\&nbsp;/, ' ')
    # remove images
    new_text.gsub!(/\s*\<img\s+[^\>]*\>/, '')
    # remove hyperlinks
    # note: this will drop waypoint URLs!
    new_text.gsub!(/\s*\<a\s+[^\>]*\>/, '')
    new_text.gsub!(/\s*\<\/a\>/, '')
    # not yet ready: do not remove but clean up hyperlinks
    # new_text.gsub!(/\&RefID=[0-9a-f-]*\&RefDS=[0-9]/, '')
    # remove form elements
    new_text.gsub!(/\s*\<input\s+[^\>]*\>/, '')
    # remove table head
    new_text.gsub!(/\s*\<thead\>.*\<\/thead\>/m, '')
    # remove spans
    new_text.gsub!(/\s*\<span\s+[^\>]*\>/, '')
    new_text.gsub!(/\s*\<\/span\>/, '')
    # remove leading and trailing blanks
    new_text.gsub!(/^\s+/, '')
    new_text.gsub!(/\s+$/, '')
    # combine table entries
    new_text.gsub!(/\<td[^\>]*\>\n+/m, '<td>')
    new_text.gsub!(/\n+\<\/td[^\>]*\>/m, '</td>')
    # ToDo: fuse continuation lines together between <td> .. </td>
    # remove "class" string from <tr>
    new_text.gsub!(/\s*class=\"[^\"]*\"/, '')
    # we have to keep the "ishidden" information for later
    if text != new_text
      debug "reduced HTML to #{new_text}"
    end
    debug "reduceHTML old: #{text.length} new: #{new_text.length}"
    return new_text
  end

  # convert waypoint "table light" into a sequence of <wpt> elements
  def toWptList(text)
    if !text
      return nil
    end
    # <table><tr><td>...</table> -> <wpt>...</wpt>
    # replace line breaks by visible separator
    hidden = false
    desc = nil
    prefix = nil
    lookup = nil
    wpname = nil
    wptype = nil
    urlwid = ""
    coord = nil
    wplat = 0
    wplon = 0
    wptlist = ""
    trcount = 0
    tdcount = 0
    # table consists of row pairs: 1st row with WP details, 2nd with note
    text.gsub(/\<br[^\>]*\>/, '|').split("\n").each { |line|
      if line =~ /\<tr/
        # start of a row - trcount is 1 for 1st, 2 for 2nd
        trcount += 1
        tdcount = 0
        # hidden waypoints will not be shown (set only in 1st row of pair)
        if line =~ /ishidden=\"true\"/
          hidden = true
        end
      elsif line =~ /\<td\>(.*)\<\/td\>/
        tdcount += 1
        # extract fields
        if trcount == 1
          # first row of two
          if tdcount == 4
            # two-letter prefix
            prefix = $1
          elsif tdcount == 5
            # dunno what it's for - future extension by gc.com?
            lookup = $1
          elsif tdcount == 6
            # WP name and type
            wpname = $1
            # extract sym type (in parentheses)
            wptype = wpname.gsub(/^.*\(/, '').gsub(/\).*/, '')
            # and drop type from name
            if wpname =~ /(.*) \(/
              wpname = $1
            end
            # we must escape special characters in WP name (as in "Park & Ride")
            wpname = makeXML(wpname)
            # we have thrown away the WID link in reduceHTML
            # this may be bad, but for now we'll wait for requests
            widurl = ""
          elsif tdcount == 7
            # coords in "written" format
            coord = $1
            # do some transformations (taken from details.rb)
            if coord =~ /([NS]) (\d+).*? ([\d\.]+) ([WE]) (\d+).*? ([\d\.]+)/
              wplat = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
              wplon = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
            end
          end
        else
          # second row of two
          if tdcount == 3
            desc = $1
            # remove some HTML stuff, but keep track of line breaks
            desc.gsub!(/\<(br|p|\/p)[^\>]*\>/, "|")
            # remove all other tags
            desc.gsub!(/\<[^\>]*\>/, "")
            # &euro; confuses gpsbabel, try to avoid - FIXME
            desc.gsub!(/\&euro;/, "EURO")
            # escape special characters, just in case
            desc = makeXML(desc)
          end
        end
      elsif line =~ /\<\/tr/
        # end of table row: did we collect info from two rows?
        if trcount == 2
          # output what has been gathered
          if hidden == false
            # replace XXXWIDXXX by WID string later!
            # Garmin Oregon shows only <desc>, not <cmt>, and limits to 48 chars
            wptlist = wptlist +
              "<wpt lat=\"#{wplat}\" lon=\"#{wplon}\">\n" +
              "  <name>#{prefix}XXXWIDXXX</name>\n" +
              "  <cmt>#{desc}</cmt>\n" +
              "  <desc>#{wpname}:#{desc}</desc>\n" +
              "  <url>http://www.geocaching.com/seek/wpt.aspx?WID=#{widurl}</url>\n" +
              "  <urlname>#{wpname}</urlname>\n" +
              "  <sym>#{wptype}</sym>\n" +
              "  <type>Waypoint|#{wptype}</type>\n" +
              "</wpt>\n"
          end
          # reset row counter and hidden flag for next WP
          hidden = false
          trcount = 0
        end
      end
    }
    if wptlist.length > 0
      debug "XML waypoints #{wptlist}"
      return wptlist
    else
      return nil
    end
  end

  def createExtraVariablesForWid(wid, symbolHash, get_location)
    cache = @wpHash[wid]
    if symbolHash
      symbols = symbolHash[wid]
    else
      symbols = ''
    end

    if cache['distance']
      relative_distance = cache['distance'].to_s + 'mi ' + cache['direction']
    else
      relative_distance = 'N/A'
    end

    if get_location
      geocoder = GeoCode.new()
      location = geocoder.lookup_coords(cache['latdata'], cache['londata'])
    else
      location = 'Undetermined'
    end
    coord_query = URI.escape("#{cache['latdata']},#{cache['londata']}")
    available = (not cache['disabled'])

    if @username and cache['visitors'].include?(@username)
      symbol = 'Geocache Found'
    else
      symbol = 'Geocache'
    end

    # waypoints
    rawWpts = cache['additional_raw']
    # make "table light": only little HTML left
    # this contains hidden WPs because of possibly important hints!
    shortWpts = nil
    if rawWpts.to_s.length > 0
      shortWpts = reduceHtml(rawWpts)
    end
    # make series of <wpt> elements containing non-hidden waypoints
    # (the ones with real coordinates)
    xmlWpts = nil
    if shortWpts.to_s.length > 0
      xmlWpts = toWptList(shortWpts)
      # add separator lines
      shortWpts = "<hr />" + shortWpts + "<hr />"
    end

    # convert attributes into XML - original code by yeryry, slightly modified
    xmlAttrs = ''
    # limit counter - to prevent "old" values slip in
    numattrib = cache['attributeCount']
    # may be uninitialized
    if numattrib
      # use attributes 0 .. (numattrib-1)
      (0 ... numattrib).each { |x|
        #debug "Looking for attribute #{x}"
        if cache["attribute#{x}id"]
          rawattrib = "      <groundspeak:attribute " +
            sprintf("id=\"%s\" inc=\"%s\">", cache["attribute#{x}id"], cache["attribute#{x}inc"]) +
            cache["attribute#{x}txt"].to_s.capitalize +
            "</groundspeak:attribute>\r\n"
          debug "Attribute #{x} XML: #{rawattrib}"
          xmlAttrs << rawattrib
        end
      }
    end

    variables = {
      'wid' => wid,
      'symbols' => symbols,
      'id' => cache['sname'],
      'mdate' => cache['mtime'].strftime("%Y-%m-%d"),
      'cdate' => cache['ctime'].strftime("%Y-%m-%d"),
      'XMLDate' => cache['ctime'].strftime("%Y-%m-%dT%H:00:00.0000000-07:00"),
      'latdatapad5' => sprintf("%2.5f", cache['latdata']),
      'londatapad5' => sprintf("%2.5f", cache['londata']),
      'latdatapad6' => sprintf("%2.6f", cache['latdata']),
      'londatapad6' => sprintf("%2.6f", cache['londata']),
      'maps_url' => "#{GOOGLE_MAPS_URL}?q=#{coord_query}",
      'IsAvailable' => available.to_s.capitalize,
      'IsArchived' => cache['archived'].to_s.capitalize,
      'location' => location,
      'relativedistance' => relative_distance,
      'hintdecrypt' => decryptHint(cache['hint']),
      'hint' => cache['hint'],
      'cacheSymbol' => symbol,
      'cacheID' => cacheID(wid),
      'trackables' => cache['travelbug'].to_s,
      'shortWpts' => shortWpts.to_s,
      'xmlWpts' => xmlWpts.to_s.gsub(/XXXWIDXXX/, wid[2 .. -1]),
      'xmlAttrs' => xmlAttrs.to_s,
      'txtAttrs' => '<b>' + cache['attributeText'].to_s.capitalize + '</b><br />',
      'warnAvail' => (available)?'':'<b>(*UNAVAIL*)</b>',
      'warnArchiv' => (cache['archived'])?'<b>(*ARCHIVED*)</b>':'',
    }
  end

  def generateOutput(title)
    debug "generating output: #{@outputType} - #{$Format[@outputType]['desc']}"
    @outVars = Hash.new
    @outVars['title'] = title
    @outVars['version'] = GTVersion.version
    debug "title: #{title} version: #{GTVersion.version}"
    updateShortNames()
    output = generatePreOutput(title)

    # ** This will be removed for GeoToad 4.0, when we use a real templating engine that can do loops **
    if @outputType =~ /html/
      html_index, symbolHash = generateHtmlIndex()
      output << html_index
    else
      symbolHash = nil
    end

    counter = 0
    @wpHash.keys.sort.each { |wid|
      cache = @wpHash[wid]
      debug "--- Output loop: #{wid} - #{cache['name']} by #{cache['creator']}"
      counter += 1
      @outVars = createExtraVariablesForWid(wid, symbolHash, @outputFormat.fetch('usesLocation', false))
      @outVars['counter'] = counter
      if @outputType =~ /gpx/
        @outVars['gpxlogs'] = createGpxCommentLogs(cache)
      end
      output << replaceVariables(@outputFormat['templateWP'], wid)
    }

    if @outputFormat['templatePost']
      output << replaceVariables(@outputFormat['templatePost'], nil)
    end
    return output
  end # end generateOutput

end
