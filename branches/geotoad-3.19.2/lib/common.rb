# -*- encoding : utf-8 -*-

# $Id$

require 'fileutils'
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
      if line =~ /\<select name=\"([^\"]*?)\"/
        current_select_name = $1
        nodebug "found select #{current_select_name}"
        prefs[current_select_name] = []
      elsif line =~ /\<option selected=\"selected\" value=\"([^\"]*?)\".*?\>(.*?)\</
        nodebug "found selected option #{$1}=#{$2}"
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

# date patterns in "last found" column (as of 2013-08-28)
#en-US	English		Today		Yesterday	(n) days ago
#de-DE	Deutsch		Heute		Gestern		vor (n) Tagen
#fr-FR	Français	Hier		Aujourd'hui	Il y a (n) jours
#pt-PT	Português	Hoje		Ontem		(n) dias atrás
#cs-CZ	Čeština		Dnes		Včera		před (n) dny
#da-DK	Dansk		I dag		I går		(n) dage siden
#sv-SE	Svenska		Idag		Igår		för (n) dagar sedan
#es-ES	Español		Hoy		Ayer		hace (n) días
#et-EE	Eesti		Täna		Eile		(n) päeva tagasi
#it-IT	Italiano	Oggi		Ieri		(n) giorni fa
#el-GR	Ελληνικά	Σήμερα		Χτές		(n) μέρες πριν
#lv-LV	Latviešu	Šodien		Vakar		pirms (n) dienām
#nl-NL	Nederlands	Vandaag		Gisteren	(n) dagen geleden
#ca-ES	Català		Avui		Ahir		Fa (n) dies
#pl-PL	Polski		Dzisiaj		Wczoraj		(n) dni temu
#nb-NO	Norsk, Bokmål	I dag		I går		(n) dager siden
#ko-KR	한국어		오늘		어제		(n) 일 전
#hu-HU	Magyar		Ma		Tegnap		(n) napja
#ro-RO	Română		Azi		Ieri		(n) zile in urmă
#ja-JP	日本語		今日		昨日		(n)日前

  def parseDate(date)
    debug "parsing date: [#{date}]"
    timestamp = nil
   # catch exceptions in case there are invalid dates (like GC1C8FF)
   begin
    # patterns may be duplicated (Dansk/Norsk) intentionally
    case date
    # relative dates end in a "*"
    when /^(Today|Heute|Hier|Hoje|Dnes|I dag|Idag|Hoy|Täna|Oggi|Σήμερα|Šodien|Vandaag|Avui|Dzisiaj|I dag|오늘|Ma|Azi|今日)\*/i
      debug "date: Today"
      days_ago=0
    when /^(Yesterday|Gestern|Aujourd.hui|Ontem|Včera|I går|Igår|Ayer|Eile|Ieri|Χτές|Vakar|Gisteren|Ahir|Wczoraj|I går|어제|Tegnap|Ieri|昨日)\*/i
      debug "date: Yesterday"
      days_ago=1
    # (any string ending with a * and a number in it)
    when /(\d)+ .+\*$/
      debug "date: #{$1} days ago"
      days_ago=$1.to_i
    # yyyy-MM-dd, yyyy/MM/dd (ISO style)
    when /^(\d{4})[\/-](\d+)[\/-](\d+)$/
      year = $1
      month = $2
      day = $3
      debug "ISO-coded date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.local(year, month, day)
    when /^(\d+)\.(\d+)\.(\d{4})$/
      year = $3
      month = $2
      day = $1
      debug "dotted date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.local(year, month, day)
    # MM/dd/yyyy, dd/MM/yyyy (need to distinguish!)
    when /^(\d+)\/(\d+)\/(\d{4})$/
      year = $3
      month = $1
      day = $2
      # interpretation depends on dateFormat
      if @@dateFormat =~ /^MM/
        debug "MM/dd/yyyy date: year=#{year} month=#{month}, day=#{day}"
      else
        temp = month
        month = day
        day = temp
        debug "dd/MM/yyyy date: year=#{year} month=#{month}, day=#{day}"
      end
      # catch errors
      begin
        timestamp = Time.local(year, month, day)
      rescue ArgumentError
        debug "Trying to swap month and day in #{year}/#{month}/#{day}"
        timestamp = Time.local(year, day, month)
      end
    # MMM/dd/yyyy
    when /^(\w{3})\/(\d+)\/(\d+)/
      year = $3
      month = $1
      day = $2
      debug "MMM/dd/yyyy date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.parse("#{day} #{month} #{year}")
    # dd/MMM/yyyy, dd MMM yy
    when /^(\d+[ \/]\w+[ \/]\d+)/
      debug "dd MMM yy[yy] date: #{$1}"
      timestamp = Time.parse(date)
    when 'N/A'
      debug "no date: N/A"
      return nil
    else
      displayWarning "Could not parse date: #{date}"
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
      #File.join(flipSlash(ENV['HOME']), '.geotoad'),
      flipSlash(ENV['GEO_DIR']),
      File.join(flipSlash(ENV['HOME']), 'Library', 'Caches'),
      File.join(flipSlash(ENV['USERPROFILE']), 'Documents and Settings'),
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
      cacheDir = File.join(cacheDir, '.geotoad', 'cache')
    elsif cacheDir == File.join(flipSlash(ENV['USERPROFILE']), 'Documents and Settings')
      cacheDir = File.join(cacheDir, 'GeoToad', 'Cache')
    else
      cacheDir = File.join(cacheDir, 'GeoToad')
      nodebug "#{cacheDir} is being used for cache"
    end
    FileUtils::mkdir_p(cacheDir, :mode => 0700)
    return cacheDir
  end

  def findConfigDir
    # find out where we want our config files
    # First check for the .geotoad directory. We may have accidentally been using it already.
    dirs = [
      File.join(flipSlash(ENV['HOME']), '.geotoad'),
      flipSlash(ENV['GEO_DIR']),
      File.join(flipSlash(ENV['HOME']), 'Library', 'Preferences'),
      File.join(flipSlash(ENV['USERPROFILE']), 'Documents and Settings'),
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
      configDir = File.join(configDir, '.geotoad')
    elsif configDir !~ /geotoad/i
      configDir = File.join(configDir, 'GeoToad')
    end
    nodebug "#{configDir} is being used for config"
    FileUtils::mkdir_p(configDir, :mode => 0700)
    return configDir
  end

  def findDataDir
    dirs = [
      File.join(File.dirname(File.realpath(__FILE__)), 'data'),
      File.join(File.dirname(File.realpath(__FILE__)), '..', 'data'),
      'data',
      File.join('..', 'data'),
      File.join(flipSlash(ENV['COMMONPROGRAMFILES']), 'GeoToad', 'data'),
      File.join(flipSlash(ENV['PROGRAMFILES']), 'GeoToad', 'data'),
      '/usr/share/geotoad/data',
      '/usr/local/share/geotoad/data'
    ]
    dirs.each {|dir|
      if File.exist?("#{dir}/funfactor.txt")
        return dir
      end
    }
    puts " ***  Could not identify data directory."
    puts " ***  If GeoToad crashes, you may want to run from the install directory."
    return File.join('..', 'data')
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
    nodebug "history: #{history.inspect}"
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