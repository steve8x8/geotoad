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
    'KILOMETER' => 'km',
    'KILOMETERS' => 'km',
    'KILOMETRES' => 'km',
    'METER'     => 'm',
    'METERS'    => 'm',
    'METRES'    => 'm',
    'MILE'      => 'mi',
    'MILES'     => 'mi',

    'CACHE'     => 'C',
    'GEOCACHE'  => 'C',
    'GEOC'	=> 'C',
    'GEOCACHING' => 'GC',
    'GEOKRET'   => 'GK',
    'GEOKRETY'  => 'GK',
    'NIGHTC'    => 'NC',

    'A'         => '',
    'AN'        => '',
    'THE'       => '',
    'AND'       => '+',
    'OR'        => '|',
    'EITHER'    => 'E',
    'ON'        => '',
    'OF'        => '',
    'FROM'      => '',
    'BY'        => '',
    'FOR'       => '',
    'IS'        => '',
    'IN'        => '',
    'WITH'      => 'W',
    'THAT'      => 'T',

    'PARK'      => 'Pk',
    'LAKE'      => 'Lk',
    'ROAD'      => 'Rd',
    'RIVER'     => '',
    'CREEK'     => 'Ck',
    'LOOP'      => 'Lp',
    'TRAIL'     => 'Tr',
    'MOUNTAIN'  => 'Mt',
    'MOUNT'     => 'Mt',
    'COUNTY'    => 'Cty',
    'OVERLOOK'  => 'Ovlk',
    'RIDGE'     => 'Rdg',
    'FOREST'    => 'Frst',
    'POINT'     => 'Pt',
    'HOTEL'     => 'Hl',
    'MOTEL'     => 'Ml',
    'CHURCH'    => 'Ch',
    'CHAPEL'    => 'Chp',
    'STATION'   => 'St',
    'FINAL'     => 'Fi',

    'MISSION'   => 'Msn',
    'IMPOSSIBLE' => 'Imp',
    'DOUBLE'    => 'Dbl',
    'LITTLE'    => 'Lil',
    'BLACK'     => 'Blk',
    'BROWN'     => 'Brn',
    'ORANGE'    => 'Org',
    'WHITE'     => 'Wht',
    'GREEN'     => 'Grn',

    'ONE'       => '1',
    'TWO'       => '2',
    'THREE'     => '3',
    'FOUR'      => '4',
    'FIVE'      => '5',
    'SIX'       => '6',
    'SEVEN'     => '7',
    'EIGHT'     => '8',
    'NINE'      => '9',
    'TEN'       => '10',
    'II'        => '2',
    'III'       => '3',
    'IV'        => '4',
    #'V'         => '5',
    'VI'        => '6',
    'VII'       => '7',
    'VIII'      => '8',
    'IX'        => '9',
    #'X'         => '10',

    'YEARS'     => 'yr',
    'YEAR'      => 'yr',
    'JANUARY'   => 'Jan',
    'FEBRUARY'  => 'Feb',
    'MARCH'     => 'Mar',
    'APRIL'     => 'Apr',
    'JUNE'      => 'Jun',
    'JULY'      => 'Jul',
    'AUGUST'    => 'Aug',
    'SEPTEMBER' => 'Sep',
    'OCTOBER'   => 'Oct',
    'NOVEMBER'  => 'Nov',
    'DECEMBER'  => 'Dec',

    # German Words Follow
    'NACHTC'    => 'NC',

    'DER'       => '',
    'DIE'       => '',
    'DAS'       => '',
    'DEN'       => '',
    'DEM'       => '',
    'DES'       => '',
    'AM'        => '',
    'ZUM'       => 'Z',
    'ZUR'       => 'Z',
    'IM'        => '',
    'INS'       => '',
    'VON'       => '',
    'VOM'       => '',
    'BEI'       => '',
    'BEIM'      => '',
    'F~R'       => '',
    'AUS'       => '',
    'AUF'       => '',
    'UM'        => '',
    'MIT'       => 'M',
    'BIS'       => '',
    'ZWISCHEN'  => 'Zw',
    '~BER'      => '',
    'UEBER'     => '',
    'OBERHALB'  => '',
    'UNTER'     => '',
    'UNTERHALB' => '',
    'OBEN'      => '',
    'UNTEN'     => '',
    'UND'       => '+',
    'ODER'      => '|',
    'ABER'      => '',

    'KIRCHE'    => 'Ki',
    'BAHNHOF'   => 'Bf',
    'PLATZ'     => 'Pl',
    'PARKPLATZ' => 'PPl',
    'NATURLEHRPFAD' => 'NLP',
    'KLEINE'    => 'Kl',
    'KLEINER'   => 'Kl',
    'KLEINEN'   => 'Kl',
    'GRO~E'     => 'Gr',
    'GRO~ER'    => 'Gr',
    'GRO~EN'    => 'Gr',
    'RUND'      => 'Rd',
    'RUNDE'     => 'Rd',
    'TEIL'      => 'T',
    #'SEE'       => 'S',
    #'BERG'      => 'Bg',
    #'BURG'      => 'Bg',

    'EIN'       => '',
    'EINE'      => '',
    'EINEN'     => '',
    'EINEM'     => '',
    'EINER'     => '',
    'ZWEI'      => '2',
    'DREI'      => '3',
    'VIER'      => '4',
    'F~NF'      => '5',
    'SECHS'     => '6',
    'SIEBEN'    => '7',
    'ACHT'      => '8',
    'NEUN'      => '9',
    'ZEHN'      => '10',

    'JAHRE'     => 'J',
    'JAHR'      => 'J',
    'JANUAR'    => 'Jan',
    'FEBRUAR'   => 'Feb',
    'M~RZ'      => 'Mar',
    'JUNI'      => 'Jun',
    'JULI'      => 'Jul',
    'OKTOBER'   => 'Okt',
    'DEZEMBER'  => 'Dez',

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
    # the "fudge factor" has to be adjusted
    #maxlength = (@waypointLength * 1.25).to_i
    maxlength = @waypointLength #+ 1
    debug "shortname: \"#{name}\"" #+ " to max. #{maxlength}"
    tempname = name[0..0].upcase + name[1..-1]
    tempname.gsub!(/cache/i, 'C')
    tempname.gsub!(/lost[\s-]*place/i, 'LP')
    tempname.gsub!(/bonus/i, 'BO')
    tempname.gsub!(/letter[\s-]*box/i, 'LBx')
    tempname.gsub!(/drive[\s-]*in/i, 'DrIn')
    tempname.gsub!(/\s+\&amp;\s+/, ' + ')
    # not sure why this isn't being handled by the \W regexps, but
    # I'm taking care of it to fix a bug with caches with _ in their name.
    tempname.gsub!(/_/, '')
    tempname.gsub!(/[~\-\#]/, ' ')
    tempname.gsub!(/\&quot;/, '"')

    # acronym.
    if tempname =~ /(\w)\. (\w)\. (\w)/
      debug "shortname: acronym detected.. removing extraneous dots and spaces"
      # Note: a bit dangerous
      tempname.gsub!(/\. /, '')
    end

    # remove long stuff in parentheses
    if tempname =~ /^(.*?)( *\(.{7,}\))(.*)/
      tempname = $1+$3.to_s
    end

    # Umlauts and other special characters: mark for later removal
    tempname.gsub!(/\&[^;]*;/, '~')

    tempwords = tempname.split(' ')
    wordcount = tempwords.length
    #debug "shortname: split \"#{tempname}\" into #{wordcount} words"

    # multiple words
    newwords = Array.new
    tempwords.each { |word|
      #debug "shortname: capitalizing \"#{word}\""
      # word.capitalize! would downcase everything else
      word = word[0..0].upcase + word[1..-1]
      newwords.push(word)
    }
    # check for short enough
    result = newwords[0..-1].join
    if result.length <= maxlength
      debug "shortname: returning \"#{result}\" (#{result.length})"
      return result
    end
    # handle all-capitals
    (1  .. wordcount).each { |index|
      # clean up
      word = newwords[-index]
      # if word is longer than 4 characters and contains no lc letter, force down
      if (word =~ /[A-Z][A-Z][A-Z][A-Z]/) and (word !~ /[a-z]/)
        word.downcase!
      end
      word = word[0..0].upcase + word[1..-1]
      newwords[-index] = word
    }
    # total length hasn't changed- no check!
    # remove extra characters word by word from right to left
    (1  .. wordcount).each { |index|
      # clean up
      word = newwords[-index]
      word.gsub!(/[^\w~+]/, '')
      newwords[-index] = word
      # check for short enough
      result = newwords[0..-1].join
      if result.length <= maxlength
        debug "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # shorten by replacing some keywords, again right to left
    (1 .. wordcount).each { |index|
      # case insensitive replacement
      word = newwords[-index]
      if word.length > 0
        #debug "shortname: testing \"#{word}\" (#{index}) for replacements"
        testWord = word.upcase
        if $ReplaceWords[testWord]
          #debug "shortname: replacing \"#{word}\" (#{index}) with \"#{$ReplaceWords[testWord]}\""
          word = $ReplaceWords[testWord]
          # do not capitalize!
          newwords[-index] = word
        end
      end
      # check for short enough
      result = newwords[0..-1].join
      if result.length <= maxlength
        debug "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # shorten by removing special characters
    (1 .. wordcount).each { |index|
      word = newwords[-index]
      word.gsub!(/[\x21-\x2f\x3a-\x3e\x5b-\x60\x7b-\x7d]/, '')
      newwords[-index] = word
      # check for short enough
      result = newwords[0..-1].join
      if result.length <= maxlength
        debug "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # shorten by removing vowels from long words first
    (1 .. wordcount).each { |index|
      word = newwords[-index]
      if word.length >= 8
        #debug "shortname: removing vowels from \"#{word}\""
        #word = word[0..0] + word[1..-1].gsub(/[AEIOUaeiou~]/, '')
        word = word[0..0] + word[1..-1].gsub(/[aeiou~]/, '')
        newwords[-index] = word
      end
      # check for short enough
      result = newwords[0..-1].join
      if result.length <= maxlength
        debug "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # shorten by removing vowels from all words
    (1 .. wordcount).each { |index|
      word = newwords[-index]
      if word.length > 0
        #debug "shortname: removing vowels from \"#{word}\""
        #word = word[0..0] + word[1..-1].gsub(/[AEIOUaeiou~]/, '')
        word = word[0..0] + word[1..-1].gsub(/[aeiou~]/, '')
        newwords[-index] = word
      end
      # check for short enough
      result = newwords[0..-1].join
      if result.length <= maxlength
        debug "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # if we got here we can't do a lot more
    result = newwords[0..-1].join
    debug "shortname: last exit, returning \"#{result}\" (#{result.length})"
    return result
  end

  # select the format for the next set of output
  def formatType=(format)
    if ($Format[format])
      @outputFormat = $Format[format].dup
      @outputType = format
      debug "format switched to #{format}"
    else
      displayWarning "Attempted to select invalid format: #{format}"
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
    file = open(file, "w")
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
        displayError "Output filter did not create file #{file}. exec was: #{exec}"
      end
    else
      debug "no exec"
      writeFile(file)
    end
  end

  def replaceVariables(templateText, wid)
    # okay. I will fully admit this is a *very* unusual way to handle
    # the templates. This all came to be due to a lot of debugging.
    debug "out.wid for #{wid.inspect} is [#{@outVars['wid'].inspect}]"
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
    # Fix numerical and hex entities such as Pateniemen l&amp;#xE4;mp&amp;#246;keskus
    text.gsub!(/\&amp;(\#[\d]+;)/, "&\\1")
    text.gsub!(/\&amp;(\#x[0-9a-fA-F]+;)/, "&\\1")

    # XML only pre-defines the following named character entities:
    text.gsub!(/\&amp;(amp;)/, "&\\1")
    text.gsub!(/\&amp;([lg]t;)/, "&\\1")
    text.gsub!(/\&amp;(quot;)/, "&\\1")
    text.gsub!(/\&amp;(apos;)/, "&\\1")

    # From http://snippets.dzone.com/posts/show/1161
    text = text.unpack("U*").collect {|s| (s > 127 ? "&##{s};" : s.chr) }.join("")

    # Collapse white space
    text.gsub!(/\&(amp;)*nbsp;/, ' ')
    text.gsub!(/[\x09\x0a\x0d]/, ' ')
    text.gsub!(/ +/, ' ')
    # Strip out control characters
    text.gsub!(/[\x00-\x1f]/, '?')
    text.gsub!(/\x7f/, '?')
    text.gsub!(/&#x[01].;/, '?')
    text.gsub!(/&#x7[fF]/, '?')

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

    # compactify whitespace
    text.gsub!(/[\r\n]+/m, "\n") # was ' '

    # rip some tags out.
    text.gsub!(/\<\/li\>/i, '')
    text.gsub!(/\<\/p\>/i, '')
    text.gsub!(/\<\/?i\>/i, '')
    text.gsub!(/\<\/?b\>/i, '')
    text.gsub!(/\<\/?body\>/i, '')
    text.gsub!(/\<\/?option.*?\>/i, '')
    text.gsub!(/\<\/?select.*?\>/i, '')
    text.gsub!(/\<\/?span.*?\>/i, '')
    text.gsub!(/\<\/?div.*?\>/i, "\n")
    text.gsub!(/\<\/?font.*?\>/i, '')
    text.gsub!(/\<\/?[uo]l\>/i, "\n")
    text.gsub!(/\s*style=\".*?\"/i, '')

    # substitute
    text.gsub!(/\<p\>/i, "\n\n")
    text.gsub!(/\<\/?tr\>/i, "\n")
    text.gsub!(/\<\/*br(\s*\/)?\>/i, "\n") #
    text.gsub!(/\<li\>/i, "\n * (o) ")
    text.gsub!(/\<img.*?\>/i, '[img]')
    text.gsub!(/\<a.*?\>/i, '[link]')
    text.gsub!(/\<a.*?\>/i, '[/link]')
    text.gsub!(/\<table.*?\>/i, "\n[table]\n")
    text.gsub!(/\<table.*?\>/i, "\n[/table]\n")
    text.gsub!(/\<.*?\>/m, '')
    text.gsub!(/\&nbsp\;/, ' ')
    text.gsub!(/\&quot\;/, '"')
    text.gsub!(/\&bdquo\;/, '"')
    text.gsub!(/\&ldquo\;/, '"')
    text.gsub!(/\&rdquo\;/, '"')
    text.gsub!(/\&apos\;/, "'")
    text.gsub!(/\&sbquo\;/, "'")
    text.gsub!(/\&lsquo\;/, "'")
    text.gsub!(/\&rsquo\;/, "'")
    text.gsub!(/\&ndash;/, ' - ')
    text.gsub!(/\&mdash;/, ' -- ')
    text.gsub!(/\&hellip;/, '...')
    text.gsub!(/\&deg;/, "'")

    text.gsub!(/\n\n\n+/, "\n\n")
    # unprintable characters
    text.gsub!(/[\x01-\x09\x0B-\x1F\x7F]/, '')
    # remaining &s
    text.gsub!(/\&/, '+')
    # kill trailing space, which makes the CSV output nicer.
    text.gsub!(/\s+$/, '')
    text.gsub!(/^\s+/m, '')
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
        debug "updateshortnames: #{shorter_name} -> #{shortest_name}"
        # If we have two caches that generate the same short name
        if snames.has_key?(shortest_name.upcase)
          other_wid = snames[shortest_name.upcase]
          other_cache = @wpHash[other_wid]
          debug "updateshortnames: Conflict found with #{shortest_name} (#{wid} vs #{other_wid})"
          unique_chars = ''
          debug "updateshortnames: Conflict resolution using #{shorter_name} and #{other_cache['snameUncut']}"
          0.upto(shorter_name.length-1) { |x|
            if shorter_name[x] != other_cache['snameUncut'][x]
              unique_chars << shorter_name[x].chr
            end
          }
          shortest_name = shorter_name[0..(@waypointLength - 4)] + unique_chars[0..3]
          debug "updateshortnames: short name unique chars: #{unique_chars} -> #{shortest_name}"
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

    #@wpHash.keys.sort.each { |wid|
    # sort GC1 < GCZZZZ < GC10000 < GCZZZZZ < GC100000
    @wpHash.keys.sort{|a,b| a[2..-1].rjust(6)<=>b[2..-1].rjust(6)}.each { |wid|
      cache = @wpHash[wid]
      symbolHash[wid] = ''

      if (cache['archived'])
        symbolHash[wid] << "<b><font color=\"#111111\">&Oslash; </font></b>"
      end

      if (cache['disabled'] and not cache['archived'])
        symbolHash[wid] << "<b><font color=\"#CC1111\">&#x229e; </font></b>"
      end

      if (cache['travelbug'])
        symbolHash[wid] << "<b><font color=\"#11CC11\">&euro;</font></b>"
      end

      if (cache['mdays'].to_i < 0)
        symbolHash[wid] << "<b><font color=\"#9900CC\">&infin;</font></b>"
      end

      if (cache['terrain'] >= 3.5)
        symbolHash[wid] << "<b><font color=\"#999922\">&sect;</font></b>"
      end

      if (cache['difficulty'] >= 3.5)
        symbolHash[wid] << "<b><font color=\"#440000\">&uarr;</font></b>"
      end

      if (cache['favfactor'].to_f >= 3.0)
        symbolHash[wid] << "<b><font color=\"#66BB66\">+</font></b>"
      end

      if (cache['funfactor'].to_f >= 3.5)
        symbolHash[wid] << "<b><font color=\"#BB6666\">&hearts;</font></b>"
      end

      index_item = "<li> #{symbolHash[wid]} "
      if (cache['mdays'].to_i < 0)
        index_item << '<strong>'
      end
      index_item << "<a href=\"\##{wid}\">#{cache['name']}</a>"
      if (cache['mdays'].to_i < 0)
        index_item << '</strong>'
      end
      index_item << " <font color=\"#444444\">(#{cache['sname']})</font></li>\n"
      index << index_item
    }
    index << '</ul>'
    return [index, symbolHash]
  end

  def createGpxCommentLogs(cache)
    #if not cache['comments']
    #  debug "No comments found for #{cache['name']}"
    #  return nil
    #end

    entries = []
    debug "Generating comment XML for #{cache['name']}"
    brlf = "\&lt;br /\&gt;\n"

    # info log entry
    if cache['ltime']
      debug "info log entry"
      entry = ''
      entry << "    <groundspeak:log id=\"-2\">\n"
      formatted_date = cache['ltime'].strftime("%Y-%m-%dT%H:%M:%SZ")
      entry << "      <groundspeak:date>#{formatted_date}</groundspeak:date>\n"
      entry << "      <groundspeak:type>Write note</groundspeak:type>\n"
      entry << "      <groundspeak:finder id=\"0\">**Info**</groundspeak:finder>\n"
      entry << "      <groundspeak:text encoded=\"False\">\n"
      formatted_date = cache['ctime'].strftime("%Y-%m-%d")
      entry << "Placed: #{formatted_date}" + brlf
      entry << "D/T/S:  #{cache['difficulty']}/#{cache['terrain']}/#{cache['size']}"
      if cache['funfactor']
        entry << ", Fun: #{cache['funfactor']}"
      end
      if cache['favfactor']
        entry << ", Fav: #{cache['favfactor']}"
      end
      entry << brlf
      if cache['logcounts']
        entry << "Stats: #{cache['logcounts']}" + brlf
        entry << "Last log: #{cache['last_find_type']}" + brlf
      end
      entry << "      </groundspeak:text>\n"
      entry << "    </groundspeak:log>\n"
      entries << entry
    end

    if cache['comments']
      cache['comments'].each { |comment|
        comment_id = Zlib.crc32(comment['text'])
        debug "Comment ID: #{comment_id} by #{comment['user']}: #{comment['text']}"
        formatted_date = comment['date'].strftime("%Y-%m-%dT07:00:00.000Z")
        entry = ''
        entry << "    <groundspeak:log id=\"#{comment_id}\">\n"
        entry << "      <groundspeak:date>#{formatted_date}</groundspeak:date>\n"
        entry << "      <groundspeak:type>#{comment['type']}</groundspeak:type>\n"
        entry << "      <groundspeak:finder id=\"#{comment['user_id']}\">#{comment['user']}</groundspeak:finder>\n"
        entry << "      <groundspeak:text encoded=\"False\">" + makeXML(comment['text']) + "</groundspeak:text>\n"
        entry << "    </groundspeak:log>\n"
        entries << entry
      }
    end
    debug "Finished generating comment XML for #{cache['name']}"
    debug "Comment Data: #{entries}"
    debug "Comment Data Length: #{entries.length}"
    return entries.join('')
  end

  def createTextCommentLogs(cache)
    if not cache['comments']
      debug "No comments found for #{cache['name']}"
      return nil
    end

    entries = []
    debug "Generating comment text for #{cache['name']}"
    cache['comments'].each { |comment|
      formatted_date = comment['date'].strftime("%Y-%m-%d")
      entry = ''
      entry << "----------\n"
      entry << "*#{comment['type']}* by #{comment['user']} on #{formatted_date}:\n"
      entry << makeText(comment['text']) + "\n"
      entries << entry
    }
    debug "Finished generating comment text for #{cache['name']}"
    debug "Comment Data: #{entries}"
    debug "Comment Data Length: #{entries.length}"
    return entries.join('')
  end

  def createHTMLCommentLogs(cache)
    if not cache['comments']
      debug "No comments found for #{cache['name']}"
      return nil
    end

    entries = []
    debug "Generating comment HTML for #{cache['name']}"
    cache['comments'].each { |comment|
      formatted_date = comment['date'].strftime("%Y-%m-%d")
      entry = ''
      entry << "<hr noshade size=\"1\" width=\"150\" align=\"left\"/>\n"
      entry << "<h4><em>#{comment['type']}</em> by #{comment['user']} on #{formatted_date}</h4>\n"
#      entry << makeXML(comment['text']) + "<br />\n\n"
      # strip images and links
      entry << comment['text'].gsub(/\<\/?img.*?\>/, '').gsub(/\<\/?a.*?\>/, '').gsub(/\<\/?font.*?\>/, '')
      entry << "<br />\n\n"
      entries << entry
    }
    debug "Finished generating comment HTML for #{cache['name']}"
    debug "Comment Data: #{entries}"
    debug "Comment Data Length: #{entries.length}"
    return entries.join('')
  end

  def decryptHint(hint)
    if hint
      # split hint into bracketed and unbracketed fragments
      decrypted = hint.gsub(/\[/, '\n[').gsub(/\]/, ']\n').split('\n').collect { |x|
        debug "hint fragment #{x}"
        if x[0..0] != '['
          # only decrypt text not within brackets
          x.tr!('A-MN-Za-mn-z', 'N-ZA-Mn-za-m')
          # re-"en"crypt HTML entities
          x.gsub!(/(\&.*?;)/) { $1.tr('A-MN-Za-mn-z', 'N-ZA-Mn-za-m') }
          debug "decrypted #{x}"
        end
        # join decrypted and unchanged fragments
        x }.join
      debug "full hint: #{decrypted}"
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
    new_text.gsub!(/\s*\<img\s+[^\>]*\>/m, '')
    # remove hyperlinks
    # note: this will drop waypoint URLs!
    new_text.gsub!(/\s*\<a\s+[^\>]*\>/m, '')
    new_text.gsub!(/\s*\<\/a\>/m, '')
    # not yet ready: do not remove but clean up hyperlinks
    # new_text.gsub!(/\&RefID=[0-9a-f-]*\&RefDS=[0-9]/, '')
    # remove form elements
    new_text.gsub!(/\s*\<input\s+[^\>]*\>/m, '')
    # remove table head
    new_text.gsub!(/\s*\<thead\>.*\<\/thead\>/m, '')
    # remove spans
    #new_text.gsub!(/\s*\<\/span\>/m, '')
    #new_text.gsub!(/\s*\<span\s+[^\>]*\>/m, '')
    new_text.gsub!(/\s*\<\/?span[^\>]*\>/m, '')
    # remove leading and trailing blanks
    new_text.gsub!(/^\s+/, '')
    new_text.gsub!(/\s+$/, '')
    # combine table entries
    new_text.gsub!(/\<td[^\>]*\>\n+/m, '<td>')
    new_text.gsub!(/\n+\<\/td[^\>]*\>/m, '</td>')
    # ToDo: fuse continuation lines together between <td> .. </td>
    # remove "class" string from <tr>
    new_text.gsub!(/\s*class=\"[^\"]*\"/m, '')
    # we have to keep the "ishidden" information for later
    if text != new_text
      debug "reduced HTML to #{new_text}"
    end
    debug "reduceHTML old: #{text.length} new: #{new_text.length}"
    return new_text
  end

  # convert waypoint "table light" into a sequence of <wpt> elements
  def toWptList(text, timestamp)
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
              #hidden = false
            else # no coordinates ("???")
              wplat = 0
              wplon = 0
              hidden = true
            end
            # convert to shortened strings
            wplat = sprintf("%2.6f", wplat)
            wplon = sprintf("%2.6f", wplon)
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
              "  <time>"+ timestamp.strftime("%Y-%m-%dT07:00:00.00Z") + "</time>\n" +
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

    if cache['distance'] and cache['direction']
      relative_distance = sprintf("%.2f", cache['distance'] || 0.0) + 'mi@' + (cache['direction'] || 'N')
      relative_distance_km = sprintf("%.2f", (cache['distance'] || 0.0) * $MILE2KM) + 'km@' + (cache['direction'] || 'N')
      relative_azimuth = sprintf("%.1f", cache['azimuth'].to_f || 0.0)
    else
      relative_distance = 'N/A'
      relative_distance_km = 'N/A'
      relative_azimuth = 'N/A'
    end

    if get_location
      geocoder = GeoCode.new()
      location = geocoder.lookup_coords(cache['latdata'], cache['londata'])
    else
      location = 'Undetermined'
    end
    coord_query = URI.escape("#{cache['latdata']},#{cache['londata']}")
    available = (not cache['disabled'] and not cache['archived'])
    archived = cache['archived']

    if @username and cache['visitors'].include?(@username)
      symbol = 'Geocache Found'
    elsif cache['atime'].to_i > $ZEROTIME
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
      xmlWpts = toWptList(shortWpts, cache['ctime'])
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
            cache["attribute#{x}txt"].to_s.capitalize.gsub(/\\/,"/") +
            "</groundspeak:attribute>\n"
          debug "Attribute #{x} XML: #{rawattrib}"
          xmlAttrs << rawattrib
        end
      }
    end

    # trackables in XML and text
    xmlTrackables = ''
    txtTrackables = ''
    if cache['travelbug'].to_s.length > 0
      cache['travelbug'].split(', ').each { |tbname|
        # we don't have the real trackable ref or id
        # therefore create a random number for the trackable
        # use a number range far above what exists now
        tbid = 801205108 + rand(923520) # = X0abcd
        # convert into string
        tbref = 'TB' + (tbid + 411120).to_s(31).upcase.tr('0-9A-U', '0-9A-HJKMNPQRTV-Z')
        debug "Trackables: use fake id #{tbid} = #{tbref} for #{tbname}"
        xmlTrackables << "\n"
        xmlTrackables << "    <groundspeak:travelbug id=\"#{tbid}\" ref=\"#{tbref}\">\n"
        xmlTrackables << "      <groundspeak:name>" + makeXML(tbname) + "</groundspeak:name>\n"
        xmlTrackables << "    </groundspeak:travelbug>\n"
        txtTrackables << makeText(tbname) + "\n"
      }
    end
    if xmlTrackables.length > 0
      debug "Generated trackables XML: #{xmlTrackables}"
    end
    if txtTrackables.length > 0
      debug "Generated trackables text: #{txtTrackables}"
    end

    variables = {
      'username' => @username,
      'wid' => wid,
      'guid' => cache['guid'].to_s,
      'symbols' => symbols,
      'id' => cache['sname'],
      'mdate' => cache['mtime'].strftime("%Y-%m-%d"),
      'cdate' => cache['ctime'].strftime("%Y-%m-%d"),
      'adate' => cache['atime'].strftime("%Y-%m-%d"),
      'size' => cache['size'].gsub(/ /, '_'),
      'favcount' => (cache['favorites'] || 0).to_s,
      'foundcount' => (cache['foundcount'] || 1).to_s,
      'favfactor' => (cache['favfactor'] || 0.0).to_s,
      'XMLDate' => cache['ctime'].strftime("%Y-%m-%dT07:00:00.000Z"),
      'latdatapad5' => sprintf("%2.5f", cache['latdata'] || 0.0),
      'londatapad5' => sprintf("%2.5f", cache['londata'] || 0.0),
      'latdatapad6' => sprintf("%2.6f", cache['latdata'] || 0.0),
      'londatapad6' => sprintf("%2.6f", cache['londata'] || 0.0),
      'maps_url' => "#{GOOGLE_MAPS_URL}?q=#{coord_query}",
      'IsAvailable' => (available==true).to_s.capitalize,
      'IsArchived' => (archived==true).to_s.capitalize,
      'location' => location,
      'relativedistance' => relative_distance,
      'relativedistancekm' => relative_distance_km,
      'relativeazimuth' => relative_azimuth,
      'hintdecrypt' => decryptHint(cache['hint']),
      'hint' => cache['hint'],
      'cacheSymbol' => symbol,
      'cacheID' => cacheID(wid),
      'logID' => (100000000001+@wpHash.length-cache['index'].to_i),
      'trackables' => cache['travelbug'].to_s,
      'xmlTrackables' => xmlTrackables,
      'shortWpts' => shortWpts.to_s,
      'xmlWpts' => xmlWpts.to_s.gsub(/XXXWIDXXX/, wid[2 .. -1]),
      'xmlAttrs' => xmlAttrs.to_s,
      'txtAttrs' => (cache['attributeText'].to_s.empty?)?'':'[' + cache['attributeText'].to_s.capitalize.gsub(/\\/,"/") + ']',
      'warnAvail' => (available)?'':'[?]',
      'warnArchiv' => (archived)?'[%]':'',
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

    # restore [backwards] search order from cache counter
    wpSearchOrder = Array.new
    @wpHash.keys.each { |wid|
      index = @wpHash[wid]['index']
      # in "-q wid" mode, there's no index
      if not index
        index = 1
      end
      wpSearchOrder[index] = wid
    }
    # remove unset elements ([0])
    wpSearchOrder.compact!
    debug "WPs in search order: #{wpSearchOrder.inspect}"
    # use wpSearchOrder.reverse_each{} for reverse search order

    counter = 0
    #@wpHash.keys.sort.each { |wid|
    (
     # arrange "-q user" queries in reverse search order
     # otherwise, sort GC1 < GCZZZZ < GC10000 < GCZZZZZ < GC100000
     (@title =~ /^GeoToad: user =/) ? (wpSearchOrder.reverse) : (@wpHash.keys.sort{|a,b| a[2..-1].rjust(6)<=>b[2..-1].rjust(6)})
    ).each { |wid|
      cache = @wpHash[wid]
      debug "--- Output loop: #{wid} - #{cache['name']} by #{cache['creator']}"
      counter += 1
      @outVars = createExtraVariablesForWid(wid, symbolHash, @outputFormat.fetch('usesLocation', false))
      @outVars['counter'] = counter
      #if @outputType =~ /gpx/
        @outVars['gpxlogs'] = createGpxCommentLogs(cache)
      #end
      #if @outputType =~ /text/
        @outVars['textlogs'] = createTextCommentLogs(cache)
      #end
      #if @outputType =~ /html/
        @outVars['htmllogs'] = createHTMLCommentLogs(cache)
      #end
      output << replaceVariables(@outputFormat['templateWP'], wid)
    }

    if @outputFormat['templatePost']
      output << replaceVariables(@outputFormat['templatePost'], nil)
    end
    return output
  end # end generateOutput

end
