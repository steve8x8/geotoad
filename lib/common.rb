# -*- encoding : utf-8 -*-

# $Id$

require 'fileutils'
require 'pathname'
require 'time'

module Common
  @@prefs_url = 'http://www.geocaching.com/account/ManagePreferences.aspx'
  # logs.aspx s=1: geocaches (default); s=2: trackables; s=3: benchmarks
  @@mylogs_url = 'http://www.geocaching.com/my/logs.aspx?s=1'
  @@mytrks_url = 'http://www.geocaching.com/my/logs.aspx?s=2'
  @@dateFormat = 'dd MMM yy'

  def getPreferences()
    page = ShadowFetch.new(@@prefs_url)
    page.localExpiry = 6 * 3600		# 6 hours
    data = page.fetch
    prefs = Hash.new
    current_select_name = nil
    data.each_line {|line|
      if line =~ /<select name=\"([^\"]*?)\"/
        current_select_name = $1
        debug3 "found select #{current_select_name}"
        prefs[current_select_name] = []
      elsif line =~ /<option selected=\"selected\" value=\"([^\"]*?)\".*?>(.*?)</
        debug3 "found selected option #{$1}=#{$2}"
        if current_select_name
          debug "setting selected option #{current_select_name}=#{$1} (#{$2})"
          prefs[current_select_name] = $1
        end
      end
    }
    dateFormat = prefs['ctl00$ContentBody$uxDateTimeFormat']
    prefLanguage = prefs['ctl00$ContentBody$uxLanguagePreference']
    if ! dateFormat.to_s.empty?
      @@dateFormat = dateFormat
    end
    return [ @@dateFormat, prefLanguage ]
  end

  def setDateFormat(dateFormat)
    @@dateFormat = dateFormat
  end

  def getMyLogs()
    page = ShadowFetch.new(@@mylogs_url)
    page.localExpiry = 12 * 3600		# 12 hours
    data = page.fetch
    foundcount = 0
    logcount = 0
    # <strong style="display: block">
    #                         1,992 Caches Found</strong>
    # (language-dependent)
    if data =~ /<strong[^>]*>\s*([\d,\.]+)[\s\w]+<\/strong>/
      foundcount = $1.gsub(/[,\.]/, '').to_i
    end
    # seen 2013-10-xx
    if data =~ /\n\s*([\d,\.]+)\s[\s\w]+<\/p>\s\n/
      logcount = $1.gsub(/[,\.]/, '').to_i
    end
    return [foundcount, logcount]
  end

  def getMyTrks()
    page = ShadowFetch.new(@@mytrks_url)
    page.localExpiry = 12 * 3600		# 12 hours
    data = page.fetch
    logcount = 0
    #     <p>
    #   2528 Results</p>
    # (not language-dependent)
    if data =~ /\n\s*([\d,\.]+)\s[\s\w]+<\/p>\s\n/
      logcount = $1.gsub(/[,\.]/, '').to_i
    end
    return logcount
  end

# date patterns in "last found" column
#en-US	English		Today		Yesterday	(n) days ago
#ca-ES	Català		Avui		Ahir		Fa (n) dies
#cs-CZ	Čeština		Dnes		Včera		před (n) dny
#da-DK	Dansk		I dag		I går		(n) dage siden
#de-DE	Deutsch		Heute		Gestern		vor (n) Tagen
#el-GR	Ελληνικά	Σήμερα		Χτές		(n) μέρες πριν
#et-EE	Eesti		Täna		Eile		(n) päeva tagasi
#es-ES	Español		Hoy		Ayer		hace (n) días
#fr-FR	Français	Hier		Aujourd'hui	Il y a (n) jours
#it-IT	Italiano	Oggi		Ieri		(n) giorni fa
#ja-JP	日本語		今日		昨日		(n)日前
#ko-KR	한국어		오늘		어제		(n) 일 전
#lv-LV	Latviešu	Šodien		Vakar		pirms (n) dienām
#hu-HU	Magyar		Ma		Tegnap		(n) napja
#nl-NL	Nederlands	Vandaag		Gisteren	(n) dagen geleden
#nb-NO	Norsk, Bokmål	I dag		I går		(n) dager siden
#pl-PL	Polski		Dzisiaj		Wczoraj		(n) dni temu
#pt-PT	Português	Hoje		Ontem		(n) dias atrás
#ro-RO	Română		Azi		Ieri		(n) zile in urmă
#ru-RU	Русский		Сегодня		Вчера		(n) дн.назад
#fi-FI	Suomi		Tänään		Eilen		(n) päivää sitten
#sv-SE	Svenska		Idag		Igår		för (n) dagar sedan

  def parseDate(date)
    debug "parsing date: [#{date}]"
    timestamp = nil
   # catch exceptions in case there are invalid dates (like GC1C8FF)
   begin
    # patterns may be duplicated (Dansk/Norsk) intentionally
    case date
    # relative dates end in a "*"
    when /^(Today|Avui|Dnes|I dag|Heute|Σήμερα|Täna|Hoy|Hier|Oggi|今日|오늘|Šodien|Ma|Vandaag|I dag|Dzisiaj|Hoje|Azi|Сегодня|Tänään|Idag)\*/i
      debug2 "date: Today"
      days_ago=0
    when /^(Yesterday|Ahir|Včera|I går|Gestern|Χτές|Eile|Ayer|Aujourd.hui|Ieri|昨日|어제|Vakar|Tegnap|Gisteren|I går|Wczoraj|Ontem|Ieri|Вчера|Eilen|Igår)\*/i
      debug2 "date: Yesterday"
      days_ago=1
    # (any string ending with a * and a number in it)
    when /(\d)+ .+\*$/
      debug2 "date: #{$1} days ago"
      days_ago=$1.to_i
    # yyyy-MM-dd, yyyy/MM/dd (ISO style)
    when /^(\d{4})[\/-](\d+)[\/-](\d+)$/
      year = $1
      month = $2
      day = $3
      debug2 "ISO-coded date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.local(year, month, day)
    when /^(\d+)\.(\d+)\.(\d{4})$/
      year = $3
      month = $2
      day = $1
      debug2 "dotted date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.local(year, month, day)
    # MM/dd/yyyy, dd/MM/yyyy (need to distinguish!)
    when /^(\d+)\/(\d+)\/(\d{4})$/
      year = $3
      month = $1
      day = $2
      # interpretation depends on dateFormat
      if @@dateFormat =~ /^MM/
        debug2 "MM/dd/yyyy date: year=#{year} month=#{month}, day=#{day}"
      else
        temp = month
        month = day
        day = temp
        debug2 "dd/MM/yyyy date: year=#{year} month=#{month}, day=#{day}"
      end
      # catch errors
      begin
        timestamp = Time.local(year, month, day)
      rescue ArgumentError
        debug2 "Trying to swap month and day in #{year}/#{month}/#{day}"
        timestamp = Time.local(year, day, month)
      end
    # MMM/dd/yyyy
    when /^(\w{3})\/(\d+)\/(\d+)/
      year = $3
      month = $1
      day = $2
      debug2 "MMM/dd/yyyy date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.parse("#{day} #{month} #{year}")
    # dd/MMM/yyyy, dd MMM yy
    when /^(\d+[ \/]\w+[ \/]\d+)/
      debug2 "dd MMM yy[yy] date: #{$1}"
      timestamp = Time.parse(date)
    when 'N/A'
      debug2 "no date: N/A"
      return nil
    else
      displayWarning "Could not parse date: #{date} - unknown language?"
      return nil
    end
   rescue => error
      displayWarning "Error encountered: #{date} #{error}"
      return nil
   end
    if not timestamp and days_ago
      timestamp = Time.now - (days_ago * 3600 * 24)
    end
    debug "Timestamp parsed as #{timestamp}"
    return timestamp
  end

  def daysAgo(timestamp)
    begin
      return (Time.now - timestamp).to_i / 86400
    rescue TypeError
      displayWarning "Could not convert timestamp '#{timestamp}' to Time object."
      return nil
    end
  end

  def flipSlash(path)
    # convert backslashes to slashes (Windows Ruby uses a mix of both)
    return path.to_s.gsub(/\\/, '/')
  end

  ## find an existing directory from a list
  def selectDirectory(dirs)
    # skip nils and empty strings
    dirs.compact.each do |dir|
      next if dir.empty?
      if File.readable?(dir) && File.stat(dir).directory?
        # write tests seem to be broken in Windows occasionally.
        if dir =~ /^\w:/ or File.stat(dir).writable?
          return dir
        end
      end
    end
    # last resort: current directory
    return flipSlash(Dir.pwd)
  end

  def findCacheDir
    # find out where we want our file cache
    dirs = [
      flipSlash(ENV['GEO_DIR']),
      # old style to be checked first
      File.join(flipSlash(ENV['HOME']), '.geotoad'),
      # XDG
      File.join(flipSlash(ENV['HOME']), '.config'),
      # MacOS
      File.join(flipSlash(ENV['HOME']), 'Library', 'Caches'),
      # Windows
      File.join(flipSlash(ENV['USERPROFILE']), 'Documents and Settings'),
      # some fallbacks
      flipSlash(ENV['HOME']),
      flipSlash(ENV['TEMP']),
      'C:/temp/',
      'C:/windows/temp',
      'C:/tmp/',
      '/var/cache',
      '/var/tmp'
    ]
    cacheDir = selectDirectory(dirs)
    # probably what we fallback to in most UNIX's.
    if cacheDir == ENV['HOME']
      # old style as there's no XDG root
      cacheDir = File.join(cacheDir, '.geotoad', 'cache')
    elsif cacheDir == File.join(flipSlash(ENV['HOME']), '.geotoad')
      cacheDir = File.join(cacheDir, 'cache')
    elsif cacheDir == File.join(flipSlash(ENV['HOME']), '.config')
      # use XDG for newly created tree
      cacheDir = File.join(cacheDir, 'GeoToad', 'cache')
    elsif cacheDir == File.join(flipSlash(ENV['USERPROFILE']), 'Documents and Settings')
      cacheDir = File.join(cacheDir, 'GeoToad', 'Cache')
    else
      cacheDir = File.join(cacheDir, 'GeoToad')
      debug3 "#{cacheDir} is being used for cache"
    end
    FileUtils::mkdir_p(cacheDir, :mode => 0700)
    return cacheDir
  end

  def findConfigDir
    # find out where we want our config files
    # First check for the .geotoad directory. We may have accidentally been using it already.
    dirs = [
      # this one would cause confusion
      #flipSlash(ENV['GEO_DIR']),
      # old style
      File.join(flipSlash(ENV['HOME']), '.geotoad'),
      # XDG style (issue 305)
      File.join(flipSlash(ENV['HOME']), '.config'),
      # MacOS
      File.join(flipSlash(ENV['HOME']), 'Library', 'Preferences'),
      # Windows
      File.join(flipSlash(ENV['USERPROFILE']), 'Documents and Settings'),
      # some fallbacks
      flipSlash(ENV['HOME']),
      flipSlash(ENV['TEMP']),
      'C:/temp',
      'C:/windows/temp',
      'C:/tmp/',
      '/var/cache',
      '/var/tmp'
    ]
    configDir = selectDirectory(dirs)
    if configDir == ENV['HOME']
      # no XDG root
      configDir = File.join(configDir, '.geotoad')
      # XDG
    elsif configDir == File.join(flipSlash(ENV['HOME']), '.config')
      configDir = File.join(configDir, 'GeoToad')
    elsif configDir !~ /geotoad/i
      configDir = File.join(configDir, 'GeoToad')
    end
    debug3 "#{configDir} is being used for config"
    FileUtils::mkdir_p(configDir, :mode => 0700)
    return configDir
  end

  def findTemplateDir
    dirs = [
      File.join(File.dirname(File.realpath(__FILE__)), 'templates'),
      File.join(File.dirname(File.realpath(__FILE__)), '..', 'templates'),
      'templates',
      File.join('..', 'templates'),
      File.join(flipSlash(ENV['COMMONPROGRAMFILES']), 'GeoToad', 'templates'),
      File.join(flipSlash(ENV['PROGRAMFILES']), 'GeoToad', 'templates'),
      '/usr/share/geotoad/templates',
      '/usr/local/share/geotoad/templates'
    ]
    dirs.each { |dir|
      if File.exist?(File.join(dir, 'geotoad.tm'))
        return dir
      end
    }
    puts " ***  Could not identify templates directory. Please report."
    return File.join('..', 'templates')
  end

  def findOutputDir
    # find out where we want to output to
    dirs = [
      flipSlash(ENV['GEO_DIR']),
      File.join(flipSlash(ENV['HOME']), 'Desktop'),
      File.join(flipSlash(ENV['HOME']), 'Skrivbord'),
      File.join(flipSlash(ENV['USERPROFILE']), 'Desktop'),
      flipSlash(ENV['HOME'])
    ]
    outputDir = selectDirectory(dirs)
    FileUtils::mkdir_p(outputDir)
    return outputDir
  end

  # convert string "i" or "i.5" to int/float number
  def tohalfint(value)
    if value.to_f == value.to_i
      return value.to_i
    else
      return value.to_f
    end
  end

  # convert lat/lon to string representation
  def lat2str(lat0, degsign="°")
    lat = lat0.to_f
    return sprintf("%s %02d%s %06.3f", ((lat >= 0) ? "N" : "S"), lat.abs.div(1), degsign, lat.abs.remainder(1) * 60.0)
  end

  def lon2str(lon0, degsign="°")
    lon = lon0.to_f
    return sprintf("%s %03d%s %06.3f", ((lon >= 0) ? "E" : "W"), lon.abs.div(1), degsign, lon.abs.remainder(1) * 60.0)
  end

  def parseCoordinate(input)
    # kinds of coordinate representations to parse (cf. geo-*):
    #
    #        -93.49130       DegDec (decimal degrees, simple format)
    #        W93.49130       DegDec (decimal degrees)
    #        -93 29.478      MinDec (decimal minutes, caching format)
    #        W93 29.478      MinDec (decimal minutes)
    #        -93 29 25       DMS
    #        W 93 29 25       DMS
    # not yet (":" is separator for input)
    #        -93:29.478      MinDec (decimal minutes, gccalc format)
    #        W93:29.478      MinDec (decimal minutes)
    #
    # this function parses a single coordinate in one of three formats
    # (NESW -> __-- has to be done before)
    # "+dd.ddd" "+dd dd.ddd" "+dd dd dd.ddd"

    # count number of fields
    case input.split("\s").length # 1, 2, or 3
    when 1 # Deg
      if input =~ /(-?)([\d\.]+)/
        value = $2.to_f
        if $1 == '-'
          value = -value
        end
      else
        debug1 "Cannot parse #{input} as degree value!"
        value = 0
      end
    when 2 # Deg Min
      if input =~ /(-?)([\d\.]+)\W+([\d\.]+)/
        value = $2.to_f + $3.to_f/60.0
        if $1 == '-'
          value = -value
        end
      else
        debug1 "Cannot parse #{input} as degree/minute value!"
        value = 0
      end
    when 3 # Deg Min Sec
      if input =~ /(-?)([\d\.]+)\W+([\d\.]+)\W+([\d\.]+)/
        value = $2.to_f + $3.to_f/60.0 + $4.to_f/3600.0
        if $1 == '-'
          value = -value
        end
      else
        debug1 "Cannot parse #{input} as degree/minute/second value!"
        value = 0
      end
    else
      # did not recognize format
      value = 0
    end
    return value
  end

  # history stuff
  def loadHistory
    historyFile  = File.join(findConfigDir, 'history.yaml')
    history = false
    if File.readable?(historyFile)
      history = YAML::load(File.open(historyFile))
    end
    if not history or (history.class != Hash)
      history = Hash.new
    end
    return history
  end

  def mergeHistory(history, cmdline, cmdhash)
    # cmdhash is _not_ hash of cmdline but of all options
    if ! history[cmdhash]
      history[cmdhash] = Hash.new()
      history[cmdhash]['count'] = 0
    end
    history[cmdhash]['count'] = history[cmdhash]['count'].to_i + 1
    history[cmdhash]['cmdline'] = cmdline
  end

  def saveHistory(history)
    configDir = findConfigDir
    historyFile  = File.join(configDir, 'history.yaml')
    begin
      File.makedirs(configDir) if (! File.exists?(configDir))
      # do not sort on output!
      File.open(historyFile, 'w'){ |f| f.puts history.to_yaml }
    rescue
    end
  end

  # mapping WID to GUID via dictionary file
  def loadMapping
    mappingFile  = File.join(findConfigDir, 'mapping.yaml')
    displayMessage "Loading dictionary from #{mappingFile}"
    mapping = false
    if File.readable?(mappingFile)
      mapping = YAML::load(File.open(mappingFile))
    end
    if not mapping or (mapping.class != Hash)
      displayInfo "No valid dictionary found, initializing"
      mapping = Hash.new
      begin
        File.open(mappingFile, 'w'){ |f| f.puts "---" }
      rescue => error
        displayWarning "Could not reset dictionary:\n\t#{error}"
      end
    end
    displayInfo "#{mapping.length} WID->GUID mappings total"
    return mapping
  end

  def getMapping(wid)
    return $mapping[wid]
  end

  def appendMapping(wid, guid)
    # this is a simple YAML file that can just be appended to
    return if $mapping[wid]
    $mapping[wid] = guid
    mappingFile  = File.join(findConfigDir, 'mapping.yaml')
    displayInfo "Writing mapping #{wid} -> #{guid}"
    begin
      File.open(mappingFile, 'a'){ |f| f.puts "#{wid}: #{guid}" }
    rescue => error
      displayWarning "Could not append mapping for #{wid}:\n\t#{error}"
    end
  end

end
