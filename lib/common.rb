# -*- encoding : utf-8 -*-

require 'fileutils'
require 'pathname'
require 'time'

module Common
  # pre 2014-10-14: @@prefs_url = 'http://www.geocaching.com/account/ManagePreferences.aspx'
  # pre 2014-10-28: @@prefs_url = 'https://www.geocaching.com/myaccount/settings/preferences'
  @@prefs_url = 'https://www.geocaching.com/account/settings/preferences'
  @@homel_url = 'https://www.geocaching.com/account/settings/homelocation'
  # logs.aspx s=1: geocaches (default); s=2: trackables; s=3: benchmarks
  @@mylogs_url = 'https://www.geocaching.com/my/logs.aspx?s=1'
  @@mytrks_url = 'https://www.geocaching.com/my/logs.aspx?s=2'
  @@dateFormat = 'dd MMM yy'

  def getPreferences()
    page = ShadowFetch.new(@@prefs_url)
    page.localExpiry = 3 * 3600		# 3 hours
    data = page.fetch
    prefs = Hash.new
    current_select_name = nil
    data.each_line{ |line|
      # pre 2014-10-14: <select name="ctl00$ContentBody$uxLanguagePreference", "ctl00$ContentBody$uxDateTimeFormat"
      # post 2014-10-14: <div class="language-dropdown native"><span class="label">Choose Your Language:</span><select>, 
      #                 <select ... name="SelectedCultureCode"><option selected="selected" value="en-US">English</option>
      #                 <select ... name="SelectedDateFormat"><option value="d.M.yyyy">15.10.2014</option>

      if line =~ /<select[^>]*name=\"([^\"]*?)\"/
        current_select_name = $1
        debug2 "found select #{current_select_name}"
        prefs[current_select_name] = []
      end
      # 2014-10-14: selected option may be on same line!
      if line =~ /<option selected=\"selected\" value=\"([^\"]*?)\".*?>(.*?)</
        debug2 "found selected option #{$1}=#{$2}"
        if current_select_name
          debug "setting selected option #{current_select_name}=#{$1} (#{$2})"
          prefs[current_select_name] = $1
          current_select_name = nil
        end
      end
    }
    # 2014-10-14
    dateFormat = prefs['SelectedDateFormat']
    prefLanguage = prefs['SelectedCultureCode']
    # fallbacks
    if dateFormat.to_s.empty?
      dateFormat = prefs['ctl00$ContentBody$uxDateTimeFormat']
    end
    if prefLanguage.to_s.empty?
      prefLanguage = prefs['ctl00$ContentBody$uxLanguagePreference']
    end
    if ! dateFormat.to_s.empty?
      @@dateFormat = dateFormat
    end
    # get center location for distance
    my_lat = nil
    my_lon = nil
    my_src = 'unknown source'
    # evaluate env variables too
    if ENV['GEO_HOME_LAT'] and ENV['GEO_HOME_LON']
      my_lat = ENV['GEO_HOME_LAT'].to_f
      my_lon = ENV['GEO_HOME_LON'].to_f
      my_src = 'GEO_HOME_* env'
    end
    if (my_lat == 0.0) and (my_lon == 0.0)
      # get location from user page, fall back
      my_lat = nil
      my_lon = nil
      page = ShadowFetch.new(@@homel_url)
      page.localExpiry = 7 * 24 * 3600
      data = page.fetch
      data.each_line{ |line|
        # var viewModel = [{"homeLocation":[51.9968514417669,-9.50660705566406], ...
        if line =~ /viewModel\s*=\s*...homeLocation.:\[([\d.-]*),([\d.-]*)\]/
          my_lat = $1.to_f
          my_lon = $2.to_f
          my_src = 'GC homeLocation'
        end
      }
    end
    debug "location #{my_lat.inspect} #{my_lon.inspect} from #{my_src}"
    return [ @@dateFormat, prefLanguage, my_lat, my_lon, my_src ]
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
    # or
    # <strong class="find-count">
    #                         3,288 Caches Found</strong>
    # (language-dependent?!)
    #if data =~ /<strong[^>]*>\s*([\d,\.]+)[\s\w]+<\/strong>/
    # <span class="cache-count">3,900 Finds</span> (2015-07-27)
    if data =~ /<span class=.cache-count.[^>]*>\s*([\d,\.]+)[\s\w]+<\/span>/
      foundcount = $1.gsub(/[,\.]/, '').to_i
    end
    # seen 2013-10-xx
    #    <p>
    #        3728 Results</p>
    #    <p>
    #if data =~ /\n\s*([\d,\.]+)\s[\s\w]+<\/p>\s\n/
    if data =~ /\n\s*<p>\s*\n\s*([\d,\.]+)\s[\s\w]+<\/p>\s*\n/
      logcount = $1.gsub(/[,\.]/, '').to_i
    end
    return [foundcount, logcount]
  end

  def getMyTrks()
    page = ShadowFetch.new(@@mytrks_url)
    page.localExpiry = 12 * 3600		# 12 hours
    data = page.fetch
    logcount = 0
    # (like log count above)
    #     <p>
    #         2528 Results</p>
    # (not language-dependent)
    #if data =~ /\n\s*([\d,\.]+)\s[\s\w]+<\/p>\s\n/
    if data =~ /\n\s*<p>\s*\n\s*([\d,\.]+)\s[\s\w]+<\/p>\s*\n/
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

# date formats (last checked: 2014-12-01) M, MM num; MMM alpha
# A	d.M.yyyy
# B	d.MM.yyyy
# C	d/M/yyyy
# D	d/MM/yyyy
# E	dd MMM yy
# F	dd.MM.yyyy
# G	dd.MMM.yyyy
# H	dd/MM/yyyy
# I	dd/MMM/yyyy
# J	dd-MM-yyyy
# K	d-M-yyyy
# L	M/d/yyyy
# M	MM/dd/yyyy
# N	MMM/dd/yyyy
# O	yyyy.MM.dd.
# P	yyyy/MM/dd
# Q	yyyy-MM-dd
#  resulting in combined patterns:
# ABFJK		d+[.-]m+[.-]y+
# CDH		d+/m+/y+ (see LM!)
# EGI		d+[ ./]MMM[ ./]y+
# LM		m+/d+/y+
# N		MMM/d+/y+
# OPQ		y+[./-]m+[./-]d+(.)?

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
    # [ABFJK] dd.MM.yyyy, d-M-yyyy etc. (dots and dashes)
    when /^(\d+)[\.-](\d+)[\.-](\d{4})$/
      year = $3
      month = $2
      day = $1
      debug2 "dotted date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.local(year, month, day)
    # [CDH] dd/MM/yyyy, [LM] MM/dd/yyyy (need to distinguish!)
    when /^(\d+)\/(\d+)\/(\d{4})$/
      year = $3
      value1 = $1
      value2 = $2
      # interpretation depends on dateFormat
      if @@dateFormat =~ /^M/
        month = value1
        day = value2
        debug2 "MM/dd/yyyy date: year=#{year} month=#{month}, day=#{day}"
      else
        day = value1
        month = value2
        debug2 "dd/MM/yyyy date: year=#{year} month=#{month}, day=#{day}"
      end
      # catch errors
      begin
        timestamp = Time.local(year, month, day)
      rescue ArgumentError
        debug2 "Trying to swap month and day in #{year}/#{month}/#{day}"
        timestamp = Time.local(year, day, month)
      end
    # [EGI] dd/MMM/yyyy, dd.MMM.yyyy (20140826), dd MMM yy
    # ToDo: i18n month names?
    when /^(\d+[ \/\.]\w{3}[ \/\.]\d{2}(\d{2})?)/
      debug2 "dd_MMM_yy[yy] date: #{$1}"
      timestamp = Time.parse(date)
    # [N] MMM/dd/yyyy
    when /^(\w{3})\/(\d+)\/(\d+)/
      year = $3
      month = $1
      day = $2
      debug2 "MMM/dd/yyyy date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.parse("#{day} #{month} #{year}")
    # [OPQ] yyyy-MM-dd, yyyy/MM/dd etc. (ISO style)
    when /^(\d{4})[\/\.-](\d+)[\/\.-](\d+)(\.)?$/
      year = $1
      month = $2
      day = $3
      debug2 "ISO-coded date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.local(year, month, day)
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
    dirs.each{ |dir|
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

  # mapping WID to GUID via dictionary file
  def loadMapping
    mappingFile  = File.join(findConfigDir, 'mapping.yaml')
    displayMessage "Dictionary: #{mappingFile}"
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
    displayInfo "#{mapping.length.to_s.rjust(6)} WID->GUID mappings total"
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
    displayInfo "Mapping #{wid} -> #{guid}"
    begin
      File.open(mappingFile, 'a'){ |f| f.puts "#{wid}: #{guid}" }
    rescue => error
      displayWarning "Could not append mapping for #{wid}:\n\t#{error}"
    end
  end

end
