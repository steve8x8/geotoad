# -*- encoding : utf-8 -*-

require 'fileutils'
require 'cgi'
require 'uri'
require 'time'
require 'zlib'
require 'base64'
require 'lib/common'
require 'lib/messages'
require 'lib/templates'
require 'lib/version'
require 'lib/geodist'

GOOGLE_MAPS_URL = 'http://maps.google.com/maps'

class Output

  include Common
  include Messages
  include GeoDist

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
    'GEOCACHE'  => 'GC',
    'GEOC'      => 'GC',
    'GEOCACHING' => 'GCing',
    'NIGHTCACHE' => 'NC',
    'NIGHTC'    => 'NC',
#   'GEOKRET'   => 'GK',
#   'GEOKRETY'  => 'GK',

    'A'         => '',
    'AN'        => '',
    'THE'       => '',
    'AND'       => '+',
    'OR'        => '|',
#   'EITHER'    => 'E',
    'ON'        => '',
    'OF'        => '',
    'FROM'      => '',
    'BY'        => '',
    'FOR'       => '',
    'IS'        => '',
    'IN'        => '',
    'WITH'      => 'W',
#    'THAT'      => 'T',

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
    'HOTEL'     => 'H',
    'MOTEL'     => 'Mo',
    'CHURCH'    => 'Ch',
    'CHAPEL'    => 'Chp',
    'STATION'   => 'St',
    'FINAL'     => 'Fi',

    'MISSION'   => 'Msn',
    'IMPOSSIBLE' => 'Imp',
    'DOUBLE'    => 'Dbl',
    'LITTLE'    => 'Lil',
    'BLACK'     => 'Blk',
#   'BROWN'     => 'Brn',
#   'ORANGE'    => 'Org',
#   'WHITE'     => 'Wht',
#   'GREEN'     => 'Grn',

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
# 2017: no longer convert Roman numerals
#   'II'        => '2',
#   'III'       => '3',
#   'IV'        => '4',
#   'V'         => '5',
#   'VI'        => '6',
#   'VII'       => '7',
#   'VIII'      => '8',
#   'IX'        => '9',
#   'X'         => '10',

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
    'NACHTCACHE' => 'NC',
    'NACHTC'    => 'NC',

    'DER'       => '',
    'DIE'       => '',
    'DAS'       => '',
    'DEN'       => '',
    'DEM'       => '',
    'DES'       => '',
#   'AN'        => '',
    'AM'        => '',
    'ZU'        => 'Z',
    'ZUM'       => 'Z',
    'ZUR'       => 'Z',
#   'IN'        => '',
    'IM'        => '',
    'INS'       => '',
    'VON'       => '',
    'VOM'       => '',
    'BEI'       => '',
    'BEIM'      => '',
    'FÜR'       => '',
    'AUS'       => '',
    'AUF'       => '',
    'UM'        => '',
    'MIT'       => 'M',
    'BIS'       => '',
    'ZWISCHEN'  => 'Zw',
    'ÜBER'      => '',
    'UEBER'     => '',
    'OBERHALB'  => '',
    'UNTER'     => '',
    'UNTERHALB' => '',
    'OBEN'      => '',
    'UNTEN'     => '',
    'UND'       => '',
    'ODER'      => '',
    'ABER'      => '',

    'KIRCHE'    => 'Ki',
    'PLATZ'     => 'Pl',
    'PARKPLATZ' => 'PPl',
    'NATURLEHRPFAD' => 'NLP',
    'BAHNHOF'   => 'Bf',
    'HAUPTBAHNHOF' => 'Hbf',
    'DEUTSCH'   => 'Dt',
    'DEUTSCHE'  => 'Dt',
    'DEUTSCHES' => 'Dt',
    'DEUTSCHER' => 'Dt',
    'KLEIN'     => 'Kl',
    'KLEINE'    => 'Kl',
    'KLEINER'   => 'Kl',
    'KLEINES'   => 'Kl',
    'KLEINEN'   => 'Kl',
    'GROß'      => 'Gr',
    'GROßE'     => 'Gr',
    'GROßER'    => 'Gr',
    'GROßEN'    => 'Gr',
    'NEUE'      => 'N',
    'NEUEN'     => 'N',
    'NEUER'     => 'N',
    'NEUES'     => 'N',
    'RUND'      => 'Rd',
    'RUNDE'     => 'Rd',
    'RUNDGANG'  => 'Rd',
    'TEIL'      => 'Tl',
    'VERSION'   => 'V',
    'VERS'      => 'V',
    'SCHWESTER' => 'Schw',
    'BRUDER'    => 'Br',

    'EIN'       => '',
    'EINE'      => '',
    'EINEN'     => '',
    'EINEM'     => '',
    'EINER'     => '',
    'EINES'     => '',
    'ZWEI'      => '2',
    'DREI'      => '3',
    'VIER'      => '4',
    'FÜNF'      => '5',
    'SECHS'     => '6',
    'SIEBEN'    => '7',
    'ACHT'      => '8',
    'NEUN'      => '9',
    'ZEHN'      => '10',

    'JAHRE'     => 'J',
    'JAHR'      => 'J',
    'JANUAR'    => 'Jan',
    'FEBRUAR'   => 'Feb',
    'MÄRZ'      => 'Mar',
    'JUNI'      => 'Jun',
    'JULI'      => 'Jul',
    'OKTOBER'   => 'Okt',
    'DEZEMBER'  => 'Dez',

  }

  ## the functions themselves ####################################################

  attr_writer :waypointLength
  attr_writer :commentLimit
  attr_writer :conditionWP

  def initialize
    @output = Array.new
    @waypointLength = 0
    @username = nil
    # initialize templates
    Templates.new if $allFormats.empty?
    @commentLimit = 10
    @conditionWP = nil
  end

  def input(data)
    @wpHash = data
  end

  $utf8lo = 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýß'
  $utf8hi = 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝß'
  # extension of Ruby's upcase/downcase
  def utf8upcase(string)
    return string.upcase.tr($utf8lo, $utf8hi)
  end

  def utf8downcase(string)
    return string.downcase.tr($utf8hi, $utf8lo)
  end

  # converts a geocache name into a much shorter name. This algorithm is
  # very sketchy and needs some real work done to it by a brave volunteer.
  # UTF-8 overhaul: 2013-12-17 (S)
  def shortName(name)
    # idea: have maxlength "a bit" longer than final @waypointLength?
    maxlength = @waypointLength
    debug2 "shortname: start with \"#{name}\""
    tempname = name.dup
    tempname = makeText(tempname)
    tempname = utf8upcase(tempname[0..0]) + tempname[1..-1].to_s
    return tempname if (tempname.length <= maxlength)

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
    tempname.gsub!(/\"/, ' ')
    debug3 "shortname: clean \"#{tempname}\""

    # remove long stuff in parentheses
    if tempname =~ /^(.*?)(\s*\(.{7,}\))(.*)/
      tempname = $1 + $3.to_s
    end

    # split into "meaningful" words, squeeze them
    newwords = Array.new
    tempname.split(/ /).each{ |word|
      # skip "empty" words
      next if word.empty?
      # word.capitalize! would downcase everything else
      word = utf8upcase(word[0..0]) + word[1..-1].to_s
      newwords.push(word)
    }
    wordcount = newwords.length
    # handle all-capitals (for readability)
    (1..wordcount).each{ |index|
      word = newwords[-index]
      # if word is longer than 4 characters and contains no lc letter, force down
      if (word =~ /[A-Z][A-Z][A-Z][A-Z]/) and (word !~ /[a-z]/)
        word = utf8upcase(word[0..0]) + utf8downcase(word[1..-1].to_s)
        newwords[-index] = word
      end
    }
    # already short enough?
    result = newwords.join
    if result.length <= maxlength
      debug2 "shortname: returning \"#{result}\" (#{result.length})"
      return result
    end
    debug3 "shortname: lower \"#{result}\""
    # shorten by removing special characters
    (1..wordcount).each{ |index|
      word = newwords[-index]
      next if (word.length <= 1)
      # keep: (blank,) digits, ? @ alpha ~; utf-8 unharmed
      word.gsub!(/[\x21-\x2f\x3a-\x3e\x5b-\x60\x7b-\x7d]/, '')
      newwords[-index] = word
      result = newwords.join
      if result.length <= maxlength
        debug2 "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    debug3 "shortname: extra \"#{result}\""
    # shorten by replacing some keywords, again right to left
    (1..wordcount).each{ |index|
      # case insensitive replacement
      word = newwords[-index]
      next if (word.length <= 1)
      testWord = utf8upcase(word)
      if $ReplaceWords[testWord]
        word = $ReplaceWords[testWord]
        # do not capitalize!
        newwords[-index] = word
      end
      result = newwords.join
      if result.length <= maxlength
        debug2 "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    debug3 "shortname: words \"#{result}\""
    # remove extra characters word by word from right to left
    (1..wordcount).each{ |index|
      word = newwords[-index]
      # non-"alpha" stuff ('i' option doesn't work!)
      word.gsub!(/[^\w#{$utf8lo}#{$utf8hi}]+/, '')
      newwords[-index] = word
      result = newwords.join
      if result.length <= maxlength
        debug2 "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    debug3 "shortname: extra \"#{result}\""
    # shorten by removing vowels from long words first
    (1..wordcount).each{ |index|
      word = newwords[-index]
      next if (word.length < 8)
      # one by one
      while (word.length > 1) and (i = word.rindex(/[aeiouäöü]/))
        word[i] = ''
        newwords[-index] = word
        break if (newwords.join.length <= maxlength)
      end
      result = newwords.join
      if result.length <= maxlength
        debug2 "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # last: shorten by removing vowels from all words
    (1..wordcount).each{ |index|
      word = newwords[-index]
      # one by one
      while (word.length > 1) and (i = word.rindex(/[aeiouäöü]/))
        word[i] = ''
        newwords[-index] = word
        break if (newwords.join.length <= maxlength)
      end
      result = newwords.join
      if result.length <= maxlength
        debug2 "shortname: returning \"#{result}\" (#{result.length})"
        return result
      end
    }
    # if we got here we can't do a lot more
    result = newwords.join
    debug2 "shortname: last exit, returning \"#{result}\" (#{result.length})"
    return result
  end

  def updateShortNames()
    # Generate short names (EasyNames). Why EasyNames have to be unique?
    # This code never fully worked - creating a "unique" name might trigger
    # a ping-pong with carefully crafted shortNames.
    # let's have another go...
    snames = {}
    @wpHash.each_key{ |wid|
      cache = @wpHash[wid]
      if (@waypointLength <= 0)
        cache['sname'] = wid.dup
        next
      end
      # get a short name, and cut down to exact length
      shorter_name = shortName(cache['name'])
      shortest_name = shorter_name[0..(@waypointLength - 1)].ljust(@waypointLength)
      # may be shorter than required!
      debug2 "updateshortnames: #{shorter_name} -> #{shortest_name}"
      # do we share this name with at least another cache?
      if snames.has_key?(utf8upcase(shortest_name))
        other_wid = snames[utf8upcase(shortest_name)]
        debug3 "updateshortnames: Conflict found with #{shortest_name} (#{wid} vs #{other_wid})"
        # we want to fill in 'GC12345' backwards, and a '#'
        unique = wid
        widlen = unique.length
        # make sure we do not underrun a short string!
        # if limited to 6, max is 12345# (and 345# for 4)
        if (widlen >= @waypointLength)
          widlen = @waypointLength - 1
        end
        # create string of exact max length, fill in wid backwards
        newname = shortest_name.ljust(@waypointLength)
        1.upto(widlen){ |i|
          newname[-i] = unique[-i]
          newname[-(i+1)] = '#'
          break if ! snames.has_key?(utf8upcase(newname))
        }
        # we might still not have resolved the issue...
        #if snames.has_key(utf8upcase(newname)) ...
        shortest_name = newname
        debug2 "updateshortnames: short name using wid: #{wid} -> #{shortest_name}"
      end
      snames[utf8upcase(shortest_name)] = wid
      cache['sname'] = shortest_name
    }
  end

  # select the format for the next set of output
  def formatType=(format)
    if $allFormats[format]
      @outputFormat = $allFormats[format].dup
      @outputType = format
      debug "format switched to #{format}"
    else
      displayWarning "Attempted to select invalid format: #{format}"
      return nil
    end
  end

  # exploratory functions.
  def formatList
    formatList = Array.new
    $allFormats.each_key{ |format|
      formatList.push(format)
    }
    formatList
  end


  def formatExtension(format)
    return $allFormats[format]['ext']
  end

  def formatDesc(format)
    return $allFormats[format]['desc']
  end

  def formatRequirement(format)
    return $allFormats[format]['required']
  end

  ## sets up for the filtering process ################3
  def prepare (title, username)
    @title = title
    @username = username

    # if we are not actually generating the output, lets do it in a meta-fashion.
    debug2 "preparing for #{@outputType}"
    if @outputFormat['filter_exec']
      post_format = @outputType
      debug3 "pre-formatting as #{@outputFormat['filter_src']} (from #{post_format})"
      self.formatType=@outputFormat['filter_src']
      debug3 "pre-format: #{@outputFormat['desc']}"
      @output = generateOutput(title)
      self.formatType = post_format
      debug3 "post-format: #{@outputFormat['desc']} via #{@outputFormat['filter_exec']}"
    else
      @output = generateOutput(title)
    end
    return @output
  end

  def writeFile (file)
    begin
      File.open(file, 'w'){ |f| f.write(@output) }
      return true
    rescue => error
      displayWarning "Error writing #{file}:\n\t#{error}"
      return false
    end
  end

  # writes the output to a file or to a program #############################
  def commit (file)
    debug2 "committing file type #{@outputType} to #{file}"
    if @outputFormat['filter_exec']
      displayInfo "Running output filter"
      debug "Executing #{@outputFormat['filter_exec']}"
      exec = @outputFormat['filter_exec'].dup
      tmpfile = File.join($CACHE_DIR, @outputType + "." + rand(500000).to_s)
      exec.gsub!('INFILE', "\"#{tmpfile}\"")
      exec.gsub!('OUTFILE', "\"#{file}\"")
      writeFile(tmpfile)
      begin
        File.unlink(file) if File.exists?(file)
      rescue
        displayWarning "Failed to unlink output file"
      end
      # if gpsbabel needs a style file, create it
      stylefile = nil
      if @outputFormat['filter_style']
        begin
          stylefile = File.join($CACHE_DIR, @outputType + ".s_" + rand(500000).to_s)
          File.open(stylefile, 'w'){ |f| f.write(@outputFormat['filter_style']) }
          exec.gsub!('STYLEFILE', "\"#{stylefile}\"")
        rescue => e
          displayWarning "Failure to write style file: #{e}"
        end
      elsif @outputFormat['filter_style64']
        begin
          stylefile = File.join($CACHE_DIR, @outputType + ".s_" + rand(500000).to_s)
          File.open(stylefile, 'w'){ |f| f.write(Base64.decode64(@outputFormat['filter_style64'])) }
          exec.gsub!('STYLEFILE', "\"#{stylefile}\"")
        rescue => e
          displayWarning "Failure to write decoded style file: #{e}"
        end
      end

      debug2 "exec = #{exec}"
      begin
        ok = system(exec)
        displayWarning "Non-zero return code #{$?.exitstatus}" if not ok
      rescue => e
        displayWarning "Something went wrong - error \"#{e}\""
      end
      # clean up temp files
      begin
        File.unlink(tmpfile) if File.exists?(tmpfile)
      rescue
        displayWarning "Failed to unlink temp file"
      end
      begin
        File.unlink(stylefile) if stylefile and File.exists?(stylefile)
      rescue
        displayWarning "Failed to unlink style file"
      end
      if not File.exists?(file)
        displayWarning "Output filter did not create file #{file}"
        displayWarning " filter_exec was: #{exec}"
      end
    else
      debug3 "no exec"
      ok = writeFile(file)
    end
    return ok
  end

  def replaceVariables(templateText, wid)
    # okay. I will fully admit this is a *very* unusual way to handle
    # the templates. This all came to be due to a lot of debugging.
    debug3 "out.wid for #{wid.inspect} is [#{@outVars['wid'].inspect}]"
    tags = templateText.scan(/<%(\w+\.\w+)%>/)
    text = templateText.dup
    tags.each{ |tag|
      (type, var) = tag[0].split('.')
      value = 'UNKNOWN_TAG'
      if (type == "wp")
        value = @wpHash[wid][var].to_s
      elsif (type == "out")
        value = @outVars[var].to_s
      # convert to XML, with some special (online-able) effects for c:geo
      elsif (type == "wpEntity" or type == "wpXML")
        value = makeXML(@wpHash[wid][var].to_s) # modify=true, remove=true
      elsif (type == "wpEntityCgeo" or type == "wpCGEO")
        value = makeXML(@wpHash[wid][var].to_s, modify=true, remove=false)
      elsif (type == "wpEntityNone" or type == "wpXML0")
        value = makeXML(@wpHash[wid][var].to_s, modify=false, remove=false)
      elsif (type == "outEntity" or type == "outXML")
        value = makeXML(@outVars[var].to_s) # modify=true, remove=true
      elsif (type == "outEntityCgeo" or type == "outCGEO")
        value = makeXML(@outVars[var].to_s, modify=true, remove=false)
      elsif (type == "outEntityNone" or type == "outXML0")
        value = makeXML(@outVars[var].to_s, modify=false, remove=false)
      # convert to text
      elsif (type == "wpText")
        value = makeText(@wpHash[wid][var].to_s)
      elsif (type == "outText")
        value = makeText(@outVars[var].to_s)
      # convert to pure-ascii text
      elsif (type == "wpTextAscii")
        value = makeText(@wpHash[wid][var].to_s).chars.map{|c| c.ascii_only? ? c : "-"}.join
      elsif (type == "outTextAscii")
        value = makeText(@outVars[var].to_s).chars.map{|c| c.ascii_only? ? c : "-"}.join
      # convert to text that can be included verbatim into XML/HTML
      elsif (type == "wpTextEntity")
        value = CGI.escapeHTML(makeText(@wpHash[wid][var].to_s))
      elsif (type == "outTextEntity")
        value = CGI.escapeHTML(makeText(@outVars[var].to_s))
      end
      # this one produces a lot of noise - make it a single line, then FIXME
      debug2 "TAG <%#{tag}%> for #{wid} -> #{value.gsub(/[\n\r]+/, '<|>')}"

      # This looks very ugly, but it works around backreference issues. Thanks ddollar!
      text.gsub!('<%' + tag[0] + '%>') { value }
    }

    debug3 "Replaced text: #{text}"
    return text
  end

  def deemoji(str, soft = true)
    return "" if str.to_s.empty?
    text = str.dup
    # pre-translate decimal into hex for large codepoints
    text.gsub!(/(\&#(\d+);)/) { ($2.to_i < 55296) ? $1 : ('&#x' + $2.to_i.to_s(16).upcase + ';') }
    # translate some UTF-16 surrogates into UTF-8 code points, remove others
    if soft
      # formula from http://www.unicode.org/faq/utf_bom.html
      text.gsub!(/\&#x(D8..);\&#x(D[CDEF]..);/i) {
        hi = $1.to_i(16)
        lo = $2.to_i(16)
        x = ((hi & 0x3f) << 10) | (lo & 0x3ff)
        u = ((hi >> 6) & 0x1f) + 1
        c = (u << 16) | x
        hex = c.to_s(16).upcase
        debug2 "converting surrogate #{$1}/#{$2} to #{hex}"
        '&#x' + hex + ';'
      }
    end
    text.gsub!(/\&#xD[89AB]..;\&#xD[CDEF]..;/i, '(*)')
    # handle unpaired surrogates
    text.gsub!(/\&#xD[89ABCDEF]..;/i, '(?)')
    return text
  end

  def makeXML(str, modify=true, remove=true)
    return "" if str.to_s.empty?
    # issue 262: "emoji" seem to break GPSr devices
    text = deemoji(str, false)
    # remove smileys
    text = icons2Text(text.dup)

    if modify
      # remove/tweak links, images
      if remove
        # text-only link representation
        text.gsub!(/<a\s.*?href=\s*[\'\"]https?:\/\/(.*?)[\'\"].*?>(.*?)<\/a.*?>/im){"[= #{$1} #{$2} =]"}
      else
        # clickable link
        text.gsub!(/(<a\s.*?href=\s*[\'\"]https?:\/\/(.*?)[\'\"].*?>)(.*?)(<\/a.*?>)/im){"#{$1}[= #{$2} =] #{$3} #{$4}"}
      end
      if remove
        # text-only image representation
        text.gsub!(/<img\s.*?src=\s*[\'\"]https?:\/\/(.*?)[\'\"].*?>/im){"[* #{$1} *]"}
      else
        # replace image reference by clickable link to avoid bandwidth consumption
        text.gsub!(/<img\s.*?src=\s*[\'\"](https?:\/\/(.*?))[\'\"].*?>/im){"<a href=\"#{$1}\">[* #{$2} *]</a>"}
      end
    end

    # fonts are not represented properly on most devices
    # avoid huge sizes, dark on black, white on white
    text.gsub!(/<\/?font[^>]*>/im, '')
    # also for style=...
    text.gsub!(/([;\'\"])\s*(background-)?color:[^;]*;/){$1}
    text.gsub!(/font-size:\d+p/, 'font-size:12p') # can be pt or px...
    #text.gsub!(/font-size:\d+p[tx]/, 'font-size:12pt') # can be pt or px...

    # escape HTML entities (including <>)
    begin
      text = CGI.escapeHTML(text)
    rescue => e
      debug "escapeHTML throws exception #{e} - use original"
    end

    # CGI.escapeHTML will try to re-escape previously escaped entities.
    # Fix numerical and hex entities such as Pateniemen l&amp;#xE4;mp&amp;#246;keskus
    text.gsub!(/\&amp;(\#[\d]+;)/, "&\\1")
    text.gsub!(/\&amp;(\#x[0-9a-fA-F]+;)/, "&\\1")

    # a lot of those entities isn't rendered by GPSr devices - simplify
    text.gsub!(/\&amp;(amp;)/, "&\\1")
    text.gsub!(/\&amp;([lg]t;)/, "&\\1")
    text.gsub!(/\&amp;(quot;)/, "&\\1")
    text.gsub!(/\&amp;(apos;)/, "&\\1")
    text.gsub!(/\&(amp;)?[rlb]dquo;/, "&quot;")
    text.gsub!(/\&(amp;)?[lr]aquo;/, "&quot;")
    text.gsub!(/\&(amp;)?[rl]squo;/, "&apos;")
    text.gsub!(/\&(amp;)?sbquo;/, "&apos;")
    text.gsub!(/\&(amp;)?ndash;/, ' - ')
    text.gsub!(/\&(amp;)?mdash;/, ' -- ')
    text.gsub!(/\&(amp;)?hellip;/, '...')

    # From http://snippets.dzone.com/posts/show/1161
    text = text.unpack("U*").collect{ |s| (s > 127 ? "&##{s};" : s.chr) }.join("")

    # Collapse white space
    text.gsub!(/\&(amp;)*nbsp;/, ' ')
    text.gsub!(/[\x09\x0a\x0d]/, ' ')
    text.gsub!(/ +/, ' ')
    # Strip out control characters
    text.gsub!(/[\x00-\x1f\x7f]/, '?')
    text.gsub!(/\&#x[01].;/, '?')
    text.gsub!(/\&#x7[fF]/, '?')

    # Fix apostrophes so that they show up as expected. Fixes issue 26.
    text.gsub!('&#8217;', "'")
    return text
  end

  def makeText(str)
    # Take HTML-like input, no matter how hacked up, and turn it into text
    # issue 262: may fail with "emoji" entities like &#xD83D;&#xDE03;
    text = deemoji(str)
    begin
      text = CGI.unescapeHTML(text)
    rescue => e
      debug "unescapeHTML throws exception #{e} - use original"
    end
    # compactify whitespace
    text.gsub!(/[\r\n]+/m, "\n") # was ' '

    # rip some tags out.
    text.gsub!(/<\/li>/i, '')
    text.gsub!(/<\/p>/i, '')
    text.gsub!(/<\/?i>/i, '')
    text.gsub!(/<\/?b>/i, '')
    text.gsub!(/<\/?body>/i, '')
    text.gsub!(/<\/?option.*?>/i, '')
    text.gsub!(/<\/?select.*?>/i, '')
    text.gsub!(/<\/?span.*?>/i, '')
    text.gsub!(/<\/?div.*?>/i, "\n")
    text.gsub!(/<\/?font.*?>/i, '')
    text.gsub!(/<\/?[uo]l>/i, "\n")
    text.gsub!(/\s*style=\s*\".*?\"/im, '')

    # substitute
    text.gsub!(/<p>/i, "\n\n")
    text.gsub!(/<\/?tr>/i, "\n")
    text.gsub!(/<\/?br(\s*\/)?>/i, "\n") #
    text.gsub!(/<li>/i, "\n * (o) ")
    text.gsub!(/<img\s.*?src=\s*[\'\"]https?:\/\/(.*?)[\'\"].*?>/im){"[* #{$1} *]"}
    text.gsub!(/<a\s.*?href=\s*[\'\"]https?:\/\/(.*?)[\'\"].*?>/im){"[= #{$1} "}
    text.gsub!(/<\/a.*?>/im, ' =]')
    text.gsub!(/<table.*?>/im, "\n[table]\n")
    text.gsub!(/<\/table.*?>/im, "\n[/table]\n")
    text.gsub!(/<.*?>/m, '')
    text.gsub!(/\&(amp;)?quot;/, '"')
    text.gsub!(/\&(amp;)?[lrb]dquo;/, '"')
    text.gsub!(/\&(amp;)?[lr]aquo;/, '"')
    text.gsub!(/\&(amp;)?apos;/, "'")
    text.gsub!(/\&(amp;)?[lr]squo;/, "'")
    text.gsub!(/\&(amp;)?sbquo;/, "'")
    text.gsub!(/\&(amp;)?nbsp;/, ' ')
    text.gsub!(/\&(amp;)?ndash;/, ' - ')
    text.gsub!(/\&(amp;)?mdash;/, ' -- ')
    text.gsub!(/\&(amp;)?hellip;/, '...')
    text.gsub!(/\&(amp;)?deg;/, "&#176;")

    text.gsub!(/\n\n\n+/, "\n\n")
    # unprintable characters
    text.gsub!(/[\x00-\x09\x0B-\x1F\x7F]/, '')
    # remaining &s
    text.gsub!(/\&/, '+')
    # kill trailing space, which makes the CSV output nicer.
    text.gsub!(/\s+$/, '')
    text.gsub!(/^\s+/m, '')
    return text
  end

  def icons2Text(str)
    iconmap = {
      "" => '[:)]',
      "_angry" => '[:(!]',
      "_approve" => '[^]',
      "_big" => '[:D]',		#big smile
      "_blackeye" => '[B)]',	#black eye
      "_blush" => '[:I]',
      "_clown" => '[:o)]',
      "_cool" => '[8D]',
      "_dead" => '[xx(]',
      "_dissapprove" => '[V]',	#disapprove
      "_disapprove" => '[V]',
      "_8ball" => '[8]',	#eightball
      "_eightball" => '[8]',
      "_evil" => '[}:)]',
      "_sad" => '[:(]',		#frown
      "_frown" => '[:(]',
      "_kisses" => '[:X]',
      "_question" => '[?]',
      "_shocked" => '[:O]',
      "_shy" => '[8)]',
      "_sleepy" => '[|)]',
      "_tongue" => '[:P]',
      "_wink" => '[;)]',
    }
    # translate smileys, remove other HTML img tags
    return str.gsub(/<img.*?icon_smile(.*?)\.gif[^>]*>/im){iconmap[$1.downcase].to_s}
  end

  def generatePreOutput(title)
    output = replaceVariables(@outputFormat['templatePre'], nil)
    # although implicit:
    return output
  end

  def generateHtmlIndex()
    # Returns an index and a hash of wid -> symbol list
    index = '<ul>'
    symbolHash = Hash.new

    # sort GC1 < GCZZZZ < GC10000 < GCZZZZZ < GC100000
    @wpHash.keys.sort{ |a,b| a[2..-1].rjust(6) <=> b[2..-1].rjust(6) }.each{ |wid|
      cache = @wpHash[wid]
      symbolHash[wid] = ''

      if cache['membersonly']
        symbolHash[wid] << "<b><font color=\"#11CC11\">&#x24; </font></b>"
      end

      if cache['archived']
        symbolHash[wid] << "<b><font color=\"#111111\">&Oslash; </font></b>"
      end

      if cache['disabled'] and not cache['archived']
        symbolHash[wid] << "<b><font color=\"#CC1111\">&#x229e; </font></b>"
      end

      if cache['travelbug']
        symbolHash[wid] << "<b><font color=\"#11CC11\">&euro;</font></b>"
      end

      if (cache['mdays'].to_i < 0)
        symbolHash[wid] << "<b><font color=\"#9900CC\">&infin;</font></b>"
      end

      if (cache['terrain'].to_f >= 3.5)
        symbolHash[wid] << "<b><font color=\"#999922\">&sect;</font></b>"
      end

      if (cache['difficulty'].to_f >= 3.5)
        symbolHash[wid] << "<b><font color=\"#440000\">&uarr;</font></b>"
      end

      if (cache['favfactor'].to_f >= 3.0)
        symbolHash[wid] << "<b><font color=\"#66BB66\">&hearts;</font></b>"
      end

      index_item = "<li> #{symbolHash[wid]} "
      if (cache['mdays'].to_i < 0)
        index_item << '<strong>'
      end
      index_item << "<a href=\"\##{wid}\">#{cache['name']}</a>"
      if (cache['mdays'].to_i < 0)
        index_item << '</strong>'
      end
      index_item << " <font color=\"#444444\">(#{wid})</font></li>\n"
      index << index_item
    }
    index << '</ul>'
    return [index, symbolHash]
  end

  def createGpxCommentLogs(cache)
    entries = []
    debug "Generating comment XML for #{cache['name']}"
    brlf = "\&lt;br /\&gt;\n"

    # remark finder id strings can be empty, do not insert userIDs or fake numbers

    # info log entry
    if (@commentLimit > 0) and cache['ltime']
      debug3 "info log entry"
      entry = ''
      entry << "    <groundspeak:log id=\"-2\">\n"
      formatted_date = cache['ltime'].getgm.strftime("%Y-%m-%dT%H:%M:%SZ")
      entry << "      <groundspeak:date>#{formatted_date}</groundspeak:date>\n"
      entry << "      <groundspeak:type>Write note</groundspeak:type>\n"
      entry << "      <groundspeak:finder id=\"\">**Info**</groundspeak:finder>\n"
      entry << "      <groundspeak:text encoded=\"True\">\n"
      if cache['logcounts']
        entry << "Last log: #{cache['last_find_type']}" + brlf
        entry << "Stats: #{cache['logcounts']}" + brlf
      end
      formatted_date = cache['ctime'].getlocal.strftime("%Y-%m-%d")
      entry << "Placed: #{formatted_date}" + brlf
      entry << "D/T/S:  #{cache['difficulty']}/#{cache['terrain']}/#{cache['size']}"
      if cache['favfactor']
        entry << ", Fav: #{cache['favfactor']}"
      end
      entry << brlf
      if cache['travelbug'].to_s.length > 0
        entry << "Trackables: #{cache['travelbug']}" + brlf
      end
      entry << "      </groundspeak:text>\n"
      entry << "    </groundspeak:log>\n"
      entries << entry
    end

    if cache['comments']
      commentcount = 0
      cache['comments'].each{ |comment|
        break if (commentcount >= @commentLimit)
        # strip images from log entries
        comment_text = icons2Text(comment['text'].to_s)
        formatted_date = comment['date'].getgm.strftime("%Y-%m-%dT%H:%M:%SZ")
        # we may actually have a valid logID, use that
        comment_id = comment['log_id'] || Zlib.crc32(comment_text + formatted_date)
        debug3 "Comment ID: #{comment_id} by #{comment['user']}: #{comment_text}"
        entry = ''
        entry << "    <groundspeak:log id=\"#{comment_id}\">\n"
        entry << "      <groundspeak:date>#{formatted_date}</groundspeak:date>\n"
        entry << "      <groundspeak:type>#{comment['type']}</groundspeak:type>\n"
        entry << "      <groundspeak:finder id=\"\">#{comment['user']}</groundspeak:finder>\n"
        entry << "      <groundspeak:text encoded=\"True\">" + makeXML(comment_text) + "</groundspeak:text>\n"
        entry << "    </groundspeak:log>\n"
        entries << entry
        commentcount += 1
      }
    end
    debug "Finished generating comment XML for #{cache['name']}"
    debug2 "Comment Data Length: #{entries.length}"
    debug3 "Comment Data: #{entries}"
    return entries.join('')
  end

  def createTextCommentLogs(cache)
    if not cache['comments']
      debug "No comments found for #{cache['name']}"
      return nil
    end

    entries = []
    debug "Generating comment text for #{cache['name']}"
    commentcount = 0
    cache['comments'].each{ |comment|
      break if (commentcount >= @commentLimit)
      comment_text = icons2Text(comment['text'].to_s)
      formatted_date = comment['date'].getlocal.strftime("%Y-%m-%d")
      # unescape HTML in finder name
      comment_user = deemoji(comment['user'], false)
      begin
        comment_user = CGI.unescapeHTML(comment_user)
      rescue => e
        debug "unescapeHTML throws exception #{e} - use original"
      end
      debug3 "Comment by #{comment['user']}: #{comment_text}"
      entry = ''
      entry << "----------\n"
      entry << "*#{comment['type']}* by #{comment_user} on #{formatted_date}:\n"
      entry << makeText(comment_text) + "\n"
      entries << entry
      commentcount += 1
    }
    debug "Finished generating comment text for #{cache['name']}"
    debug2 "Comment Data Length: #{entries.length}"
    debug3 "Comment Data: #{entries}"
    return entries.join('')
  end

  def createHTMLCommentLogs(cache)
    if not cache['comments']
      debug "No comments found for #{cache['name']}"
      return nil
    end

    entries = []
    debug "Generating comment HTML for #{cache['name']}"
    commentcount = 0
    cache['comments'].each{ |comment|
      break if (commentcount >= @commentLimit)
      formatted_date = comment['date'].getlocal.strftime("%Y-%m-%d")
      entry = ''
      entry << "<hr noshade size=\"1\" width=\"150\" align=\"left\"/>\n"
      entry << "<h4><em>#{comment['type']}</em> by #{comment['user']} on #{formatted_date}</h4>\n"
      # strip images and links
      entry << comment['text'].gsub(/<\/?img.*?>/, '').gsub(/<\/?a.*?>/, '').gsub(/<\/?font.*?>/, '')
      entry << "<br />\n\n"
      entries << entry
      commentcount += 1
    }
    debug "Finished generating comment HTML for #{cache['name']}"
    debug2 "Comment Data Length: #{entries.length}"
    debug3 "Comment Data: #{entries}"
    return entries.join('')
  end

  def decryptHint(hint)
    decrypted = ''
    if hint
      # translate smileys
      hint2 = icons2Text(hint)
      # split hint into bracketed and unbracketed fragments
      decrypted = hint2.gsub(/\[/, '\n[').gsub(/\]/, ']\n').split('\n').collect{ |x|
        debug3 "hint fragment #{x}"
        if x[0..0] != '['
          # only decrypt text not within brackets
          x.tr!('A-MN-Za-mn-z', 'N-ZA-Mn-za-m')
          # re-"en"crypt HTML entities
          x.gsub!(/(\&.*?;)/) { $1.tr('A-MN-Za-mn-z', 'N-ZA-Mn-za-m') }
          debug3 "decrypted #{x}"
        end
        # join decrypted and unchanged fragments
        x }.join
      debug "full hint: #{decrypted}"
    end
    return decrypted
  end

  # reduce HTML content (of waypoint table) to a minimum
  # suited for GPSr and parsing in toWptList()
  def reduceHtml(text)
    return nil if not text
    # un-fix spaces
    new_text = text.gsub(/\s*\&nbsp;/, ' ')
    # remove images
    new_text.gsub!(/\s*<img\s+[^>]*>/m, '')
    # remove hyperlinks
    # note: this will drop waypoint URLs!
    new_text.gsub!(/\s*<a\s+[^>]*>/m, '')
    new_text.gsub!(/\s*<\/a>/m, '')
    # remove form elements
    new_text.gsub!(/\s*<input\s+[^>]*>/m, '')
    # remove table head
    new_text.gsub!(/\s*<thead>.*<\/thead>/m, '')
    # remove spans
    new_text.gsub!(/\s*<\/?span[^>]*>/m, '')
    # remove leading and trailing blanks
    new_text.gsub!(/^\s+/, '')
    new_text.gsub!(/\s+$/, '')
    # combine table entries
    new_text.gsub!(/<td[^>]*>\n+/m, '<td>')
    new_text.gsub!(/\n+<\/td[^>]*>/m, '</td>')
    # ToDo: fuse continuation lines together between <td> .. </td>
    # remove "class" string from <tr>
    new_text.gsub!(/\s*class=\"[^\"]*\"/m, '')
    # we have to keep the "ishidden" information for later
    if text != new_text
      debug3 "reduced HTML to #{new_text}"
    end
    debug2 "reduceHTML old: #{text.length} new: #{new_text.length}"
    return new_text
  end

  # convert waypoint "table light" into a sequence of <wpt> elements
  def toWptList(text, timestamp)
    return nil if not text
    # <table><tr><td>...</table> -> <wpt>...</wpt>
    # replace line breaks by visible separator
    hidden = false
    desc = nil
    prefix = nil
    lookup = nil
    wpname = nil
    wptype = nil
    coord = nil
    wplat = 0
    wplon = 0
    wptlist = ""
    trcount = 0
    tdcount = 0
    # table consists of row pairs: 1st row with WP details, 2nd with note
    text.gsub(/<br[^>]*>/, '|').split("\n").each{ |line|
      if line =~ /<tr/
        # start of a row - trcount is 1 for 1st, 2 for 2nd
        trcount += 1
        tdcount = 0
        # hidden waypoints will not be shown (set only in 1st row of pair)
        if line =~ /ishidden=\"true\"/
          hidden = true
        end
      elsif line =~ /<td>(.*)<\/td>/
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
            # extract sym type (in parentheses), replace outdated types (from old cdpfs)
            wptype = wpname.gsub(/^.*\(/, '').gsub(/\).*/, '')
            wptype = wptype.gsub(/Question to Answer/i, 'Virtual Stage').gsub(/Stages of a Multicache/i, 'Physical Stage')
            # and drop type from name
            if wpname =~ /(.*) \(/
              wpname = $1
            end
            # we must escape special characters in WP name (as in "Park & Ride")
            wpname = makeXML(wpname)
          elsif tdcount == 7
            # coords in "written" format
            coord = $1
            # do some transformations (taken from details.rb)
            if coord =~ /([NS]) (\d+).*? ([\d\.]+) ([WE]) (\d+).*? ([\d\.]+)/
              wplat = ($2.to_f + $3.to_f / 60) * ($1 == 'S' ? -1:1)
              wplon = ($5.to_f + $6.to_f / 60) * ($4 == 'W' ? -1:1)
            else # no coordinates ("???") -> <wpt>
              # make "zero" waypoints available for c:geo etc.
              wplat = nil
              wplon = nil
            end
            # convert to shortened strings
            if wplat
              wplat = sprintf("%.6f", wplat)
            end
            if wplon
              wplon = sprintf("%.6f", wplon)
            end
          end
        else
          # second row of two
          if tdcount == 3
            desc = $1
            # remove some HTML stuff, but keep track of line breaks
            desc.gsub!(/<(br|p|\/p)[^>]*>/, "|")
            # remove all other tags
            desc.gsub!(/<[^>]*>/, "")
            # &euro; confuses gpsbabel, try to avoid
            desc.gsub!(/\&euro;/, "EURO")
            # escape special characters, just in case
            desc = makeXML(desc)
          end
        end
      elsif line =~ /<\/tr/
        # end of table row: did we collect info from two rows?
        if trcount == 2
          # output what has been gathered
          if hidden == false
            # replace XXXWIDXXX by WID string later!
            # Garmin Oregon shows only <desc>, not <cmt>, and limits to 48 chars
            # GSAK waypoints carry more info, c:geo can also handle locationless
            # return all info we may need, strip later
            wptlist << "<wpt" +
                ((wplat and wplon) ? " lat=\"#{wplat}\" lon=\"#{wplon}\"" : "") +
                ">\n" +
              "  <name>#{prefix}XXXWIDXXX</name>\n" +
              "  <cmt>#{desc}</cmt>\n" +
              "  <desc>#{wpname}" +
                ((desc.to_s.length > 0) ? ":#{desc}" : "") +
                "</desc>\n" +
              "  <sym>#{wptype}</sym>\n" +
              "  <type>Waypoint|#{wptype}</type>\n" +
              "  <gsak:wptExtension>\n" +
              "    <gsak:Parent>GCXXXWIDXXX</gsak:Parent>\n" +
              "  </gsak:wptExtension>\n" +
              "</wpt>\n"
          end
          # reset row counter and hidden flag for next WP
          hidden = false
          trcount = 0
        end
      end
    }
    if wptlist.length > 0
      debug3 "XML waypoints #{wptlist}"
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

    # we may have got a distance from the search
    # if there's a home location, use that instead
    newDistance, newDirection = geoDistDir($my_lat, $my_lon, cache['latdata'], cache['londata'])
    # will return nil if input is missing
    if newDistance and newDirection
      cache['distance'] = newDistance
      cache['direction'] = newDirection
    end
    if cache['distance'] and cache['direction']
      distmi = (cache['distance'] || 0.0)
      distkm = distmi * $MILE2KM
      relative_distance    = sprintf((distmi >= 1.0) ? "%5.1f" : "%5.2f", distmi) + 'mi@' + (cache['direction'] || 'N')
      relative_distance_km = sprintf((distkm >= 1.0) ? "%5.1f" : "%5.2f", distkm) + 'km@' + (cache['direction'] || 'N')
    else
      relative_distance = 'N/A'
      relative_distance_km = 'N/A'
    end

    if get_location
      geocoder = GeoCode.new()
      location = geocoder.lookup_coords(cache['latdata'].to_f, cache['londata'].to_f)
    else
      location = 'Undetermined'
    end
    coord_query = URI.escape(sprintf("%.6f,%.6f", cache['latdata'].to_f, cache['londata'].to_f))
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
    # make series of <wpt> elements
    xmlWptsCgeo = nil
    xmlWptsGsak = nil
    xmlWpts = nil
    if shortWpts.to_s.length > 0
      xmlWptsCgeo = toWptList(shortWpts, cache['ctime'])
      if xmlWptsCgeo
        # remove locationless wpts
        xmlWptsGsak = xmlWptsCgeo.gsub(/<wpt( lat="0.000000*" lon="0.000000*")?>.*?<\/wpt>\s*/m, '')
        # strip desc strings
        xmlWptsCgeo.gsub!(/<desc>(.*?):.*?<\/desc>/){"<desc>#{$1}</desc>"}
      end
      if xmlWptsGsak
        # remove gsak additions
        xmlWpts = xmlWptsGsak.each_line.map{|l| (l=~/<\/?gsak:/)?nil:l}.compact.join
      end
      # add separator lines
      shortWpts = "<hr />" + shortWpts + "<hr />"
    end

    # convert attributes into XML - original code by yeryry, slightly modified
    xmlAttrs = ''
    # limit counter - to prevent "old" values slip in
    numattrib = cache['attributeCount']
    # may be uninitialized
    if numattrib
      # use attributes 0..(numattrib-1)
      (0...numattrib).each{ |x|
        if cache["attribute#{x}id"]
          rawattrib = "      <groundspeak:attribute " +
            sprintf("id=\"%s\" inc=\"%s\">", cache["attribute#{x}id"], cache["attribute#{x}inc"]) +
            cache["attribute#{x}txt"].to_s.capitalize.gsub(/\\/, "/") +
            "</groundspeak:attribute>\n"
          debug3 "Attribute #{x} XML: #{rawattrib}"
          xmlAttrs << rawattrib
        end
      }
    end

    # trackables in XML and text
    xmlTrackables = ''
    txtTrackables = ''
    if cache['travelbug'].to_s.length > 0
      cache['travelbug'].split(', ').each{ |tbname|
        # 20160830: no longer fake TB ID or ref
        xmlTrackables << "\n"
        xmlTrackables << "    <groundspeak:travelbug ref=\"\">\n"
        xmlTrackables << "      <groundspeak:name>" + makeXML(tbname) + "</groundspeak:name>\n"
        xmlTrackables << "    </groundspeak:travelbug>\n"
        # separator between TBs
        if txtTrackables.length > 0
          txtTrackables << "; "
        end
        txtTrackables << makeText(tbname)
      }
    end
    if xmlTrackables.length > 0
      # get XML indentation right
      xmlTrackables << "  "
      debug3 "Generated trackables XML: #{xmlTrackables}"
    end
    if txtTrackables.length > 0
      debug3 "Generated trackables text: #{txtTrackables}"
    end

    begin
    variables = {
      'username'    => @username,
      'wid'         => wid,
      'guid'        => cache['guid'].to_s,
      'symbols'     => symbols,
      'id'          => cache['sname'],
      'csize'       => cache['size'].capitalize,
      'ctime'       => cache['ctime'].getgm.strftime("%Y-%m-%dT%H:%M:%SZ"),
      'ctime_hm'    => cache['ctime'].getgm.strftime("%Y-%m-%dT%H:%MZ"),
      'cdate'       => cache['ctime'].getlocal.strftime("%Y-%m-%d"),
      'cdateshort'  => cache['ctime'].getlocal.strftime("%y%m%d"),
      'atime'       => cache['atime'].getgm.strftime("%Y-%m-%dT%H:%M:%SZ"),
      'atime_hm'    => cache['atime'].getgm.strftime("%Y-%m-%dT%H:%MZ"),
      'adate'       => cache['atime'].getlocal.strftime("%Y-%m-%d"),
      'mtime'       => cache['mtime'].getgm.strftime("%Y-%m-%dT%H:%M:%SZ"),
      'mtime_hm'    => cache['mtime'].getgm.strftime("%Y-%m-%dT%H:%MZ"),
      'mdate'       => cache['mtime'].getlocal.strftime("%Y-%m-%d"),
      'size'        => (cache['size'] || 'empty').to_s.gsub(/ /, '_'),
      'type8'       => (cache['type'] || 'unknown').ljust(8),
      'favcount'    => (cache['favorites'] || 0).to_s,
      'foundcount'  => (cache['foundcount'] || '?').to_s,
      'favfactor'   => (cache['favfactor'] || 0.0).to_s,
      'latdatapad5' => sprintf("%2.5f", cache['latdata'] || 0.0),
      'londatapad5' => sprintf("%2.5f", cache['londata'] || 0.0),
      'latdatapad6' => sprintf("%2.6f", cache['latdata'] || 0.0),
      'londatapad6' => sprintf("%2.6f", cache['londata'] || 0.0),
      'latdegmin'   => lat2str(cache['latdata'] || 0.0, degsign=':').gsub(/ */, '').gsub(/([NSEW])0+/, '\1'),
      'londegmin'   => lon2str(cache['londata'] || 0.0, degsign=':').gsub(/ */, '').gsub(/([NSEW])0+/, '\1'),
      'maps_url'    => "#{GOOGLE_MAPS_URL}?q=#{coord_query}",
      'IsAvailable' => (available == true).to_s.capitalize,
      'IsArchived'  => (archived == true).to_s.capitalize,
      'IsPremium'   => (cache['membersonly'] == true).to_s, # do not capitalize!
      'FavPoints'   => cache['favorites'] || 0,
      # cartridge CGUID has 36 characters, so has the "dummy" one
      'cartridge'   => (cache['cartridge'] || '_no_link_to_wherigo_cartridge_found_'),
      'location'    => location,
      'relativedistance'   => relative_distance,
      'relativedistancekm' => relative_distance_km,
      'hintdecrypt' => decryptHint(cache['hint']),
      'hint'        => cache['hint'],
      'cacheSymbol' => symbol,
      'cacheID'     => cacheID(wid),
      'logID'       => (100000000001 + @wpHash.length - cache['index'].to_i),
      'trackables'  => cache['travelbug'].to_s,
      'xmlTrackables' => xmlTrackables,
      'shortWpts'   => shortWpts.to_s,
      'xmlWptsCgeo' => xmlWptsCgeo.to_s.gsub(/XXXWIDXXX/, wid[2..-1]),
      'xmlWptsGsak' => xmlWptsGsak.to_s.gsub(/XXXWIDXXX/, wid[2..-1]),
      'xmlWpts'     => xmlWpts.to_s.gsub(/XXXWIDXXX/, wid[2..-1]),
      'xmlAttrs'    => xmlAttrs.to_s,
      'txtAttrs'    => (cache['attributeText'].to_s.empty?) ? '' : '[' + cache['attributeText'].to_s.capitalize.gsub(/\\/, "/") + ']',
      'warnAvail'   => (available or archived) ? '' : '[?]',
      'warnArchiv'  => (archived) ? '[%]' : '',
      'premiumOnly' => (cache['membersonly'] ? ('[$' + (cache['olddesc'] ? '+' : '') + (cache['moved'] ? 'm' : '') + ']') : ''),
      'nuvi'        => cache['type'][0..1].capitalize +
        sprintf("%.1f", cache['difficulty']).gsub(/\.5/, '\'').gsub(/\.0/, '.') +
        sprintf("%.1f", cache['terrain']).gsub(/\.5/, '\'').gsub(/\.0/, '.') +
        cache['size'][0..1].capitalize +
          ((cache['membersonly']) ? '$' : '') +
            (cache['olddesc'] ? '+' : '') + (cache['moved'] ? 'm' : '') +
          ((archived) ? '%' : '') +
          ((available or archived) ? '' : '?'),
      # Premium/Archive/Disabled
      'pad'         => ((cache['membersonly']) ? '$' : '') +
                        (cache['olddesc'] ? '+' : '') + (cache['moved'] ? 'm' : '') +
                        ((archived) ? '%' : '') +
                        ((available or archived) ? '' : '?'),
    }
    rescue => e
      displayWarning "Problem (#{e}) while converting cache #{wid}:\n#{cache.inspect}"
      displayError "Backtrace: #{e.backtrace}"
    end
    return variables
  end

  def generateOutput(title)
    debug3 "generating output: #{@outputType} - #{$allFormats[@outputType]['desc']}"
    @outVars = Hash.new
    @outVars['title'] = title
    @outVars['version'] = GTVersion.version
    debug "title: #{title} version: #{GTVersion.version}"
    updateShortNames()
    output = generatePreOutput(title)

    if @outputType =~ /html/
      html_index, symbolHash = generateHtmlIndex()
      output << html_index
    else
      symbolHash = nil
    end

    # restore [backwards] search order from cache counter
    wpSearchOrder = Array.new
    helpindex = 0
    @wpHash.keys.each{ |wid|
      helpindex += 1
      # in "-q wid" mode, there's no index
      index = @wpHash[wid]['index'] || helpindex
      wpSearchOrder[index] = wid
    }
    # remove unset elements ([0])
    wpSearchOrder.compact!
    debug2 "WPs in search order: #{wpSearchOrder.inspect}"
    # use wpSearchOrder.reverse_each{} for reverse search order

    counter = 0
    (
     # arrange "-q user" queries in reverse search order
     # otherwise, sort GC1 < GCZZZZ < GC10000 < GCZZZZZ < GC100000
      (@title =~ /^GeoToad: user =/) ?
        wpSearchOrder.reverse
        :
        @wpHash.keys.sort{ |a,b| a[2..-1].rjust(6) <=> b[2..-1].rjust(6) }
    ).each{ |wid|
      # unescape HTML entities in _some_ fields (if not done yet)
      ['name', 'creator'].each{ |var|
        temp = deemoji(@wpHash[wid][var], false)
        begin
          @wpHash[wid][var] = CGI.unescapeHTML(temp)
        rescue => e
          debug "unescapeHTML error: #{e}"
          @wpHash[wid][var] = temp.gsub(/&/, '+')
        end
      }
      cache = @wpHash[wid]
      debug "--- Output loop: #{wid} - #{cache['name']} by #{cache['creator']}"
      counter += 1
      @outVars = createExtraVariablesForWid(wid, symbolHash, @outputFormat.fetch('usesLocation', false))
      @outVars['counter'] = counter
      @outVars['gpxlogs'] = createGpxCommentLogs(cache)
      @outVars['textlogs'] = createTextCommentLogs(cache)
      @outVars['htmllogs'] = createHTMLCommentLogs(cache)
      # make output conditional
      willOutput = true
      if @outputFormat['conditionWP'] or @conditionWP
        condition1 = @outputFormat['conditionWP'] || true
        condition2 = @conditionWP || true
        conditionWP = "( (#{condition1}) and (#{condition2}) )"
        debug "WP condition #{conditionWP.inspect}"
        condition = replaceVariables(conditionWP, wid)
        debug "gives condition #{condition.inspect}"
        begin
          willOutput = eval(condition)
          debug "result #{willOutput.inspect}"
        rescue => e
          displayWarning "Problem with output condition \"#{condition}\":\n\t#{e}, assuming false"
          willOutput = false
        end
        debug "WP condition for #{wid}: #{willOutput.inspect}"
      end
      if willOutput
        outputadd = replaceVariables(@outputFormat['templateWP'], wid)
        maxlength = @outputFormat['maxlengthWP']
        if maxlength and outputadd.length > maxlength
          output << outputadd[0..maxlength-2] + "_" #+ outputadd[-1..-1]
        else
          output << outputadd
        end
      end
    }

    if @outputFormat['templatePost']
      output << replaceVariables(@outputFormat['templatePost'], nil)
    end
    return output
  end # end generateOutput

end
