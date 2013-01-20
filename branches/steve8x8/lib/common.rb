# $Id$
require 'fileutils'

module Common
  @@prefs_url = 'http://www.geocaching.com/account/ManagePreferences.aspx'
  # logs.aspx s=1: geocaches (default); s=2: trackables; s=3: benchmarks
  @@mylogs_url = 'http://www.geocaching.com/my/logs.aspx?s=1'
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
        debug "found select #{current_select_name}"
        prefs[current_select_name] = []
      elsif line =~ /\<option selected=\"selected\" value=\"([^\"]*?)\".*?\>(.*?)\</
          debug "found selected option #{$1}=#{$2}"
        if current_select_name
          debug "setting selected option #{current_select_name}=#{$1}"
          prefs[current_select_name] = $1
        end
      end
    }
    dateFormat = prefs['ctl00$ContentBody$uxDateTimeFormat']
    if ! dateFormat.to_s.empty?
      @@dateFormat = dateFormat
    end
    return @@dateFormat
  end

  def setDateFormat(dateFormat)
    @@dateFormat = dateFormat
  end

  def getMyLogs()
    page = ShadowFetch.new(@@mylogs_url)
    page.localExpiry = 12 * 3600		# 12 hours
    data = page.fetch
    counter = 0
    # <strong style="display:block">
    #                        <img src="/images/icons/icon_smile.png" title="Caches Found" /> 1,992</strong>
    if data =~ /title=.Caches Found.*?([\d,\.]+)/
      counter = $1.gsub(/[,\.]/, '').to_i
    end
    return counter
  end

  def parseDate(date)
    debug "parsing date: [#{date}]"
    timestamp = nil
   # catch exceptions in case there are invalid dates (like GC1C8FF)
   begin
    # we have to overcome the ignorance of ruby1.8 wrt Unicode characters
    case date
    # relative dates end in a "*"
    # Languages: (no Korean for now, and perhaps never with ruby1.8)
    # en|de|fr|pt|cz
    # se/no|nl|ca|pl|et
    # es|hu|ro|lt|it
    when /^(Today|Heute|Hier|Hoje|Dnes)\*/i
      debug "date: Today"
      days_ago=0
    when /^(I ?dag|Vandaag|Avui|Dzisiaj|T.{1,2}na)\*/i
      debug "date: Today"
      days_ago=0
    when /^(Hoy|Ma|Azi|.{1,2}odien|Oggi)\*/i
      debug "date: Today"
      days_ago=0
    when /^(Yesterday|Gestern|Aujourd.{1,2}hui|Ontem|V.{1,2}era)\*/i
      debug "date: Yesterday"
      days_ago=1
    when /^(I ?g.{1,2}r|Gisteren|Ahir|Wczoraj|Eile)\*/i
      debug "date: Yesterday"
      days_ago=1
    when /^(Ayer|Tegnap|Ieri|Vakar|Ieri)\*/i
      debug "date: Yesterday"
      days_ago=1
    # Eesti: 6 päeva tagasi*
    # Latviešu: pirms 6 dienām*
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
    when /^(\w{3})\/(\d+)\/(\d+)/
      year = $3
      month = $1
      day = $2
      debug "MMM/dd/yyyy date: year=#{year} month=#{month} day=#{day}"
      timestamp = Time.parse("#{day} #{month} #{year}")
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

  ## finds a place to put temp files on the system ###################################
  def selectDirectory(dirs)
    dirs.compact.each do |dir|
      dir = dir.gsub(/\\/, '/')
      if File.exists?(dir) && File.stat(dir).directory?
        # write tests seem to be broken in Windows occassionaly.
        if dir =~ /^\w:/ or File.stat(dir).writable?
          return dir
        end
      end
    end
    return Dir.pwd.gsub(/\\/, '/')
  end

  def findCacheDir
    # find out where we want our cache #############################
    cacheDir=selectDirectory([ENV['GEO_DIR'], "#{ENV['HOME']}/Library/Caches", "#{ENV['USERPROFILE']}/Documents and Settings", ENV['HOME'], ENV['TEMP'],
        "C:/temp/", "C:/windows/temp", "C:/tmp/", "/var/tmp"])

    # probably what we fallback to in most UNIX's.
    if cacheDir == ENV['HOME']
      cacheDir=cacheDir + '/.geotoad/cache'
    elsif cacheDir == "#{ENV['USERPROFILE']}/Documents and Settings"
      cacheDir=cacheDir + "/GeoToad/Cache"
    else
      cacheDir=cacheDir + "/GeoToad"
      debug "#{cacheDir} is being used for cache"
    end

    FileUtils::mkdir_p(cacheDir, :mode => 0700)
    return cacheDir
  end
  def findConfigDir
    # find out where we want our cache #############################
    # First check for the .geotoad directory. We may have accidentally been using it already.
    dirs = ["#{ENV['HOME']}/.geotoad",
            ENV['GEO_DIR'],
            "#{ENV['HOME']}/Library/Preferences",
            "#{ENV['USERPROFILE']}/Documents and Settings",
            ENV['HOME'],
            'C:/temp/',
            'C:/windows/temp',
            '/var/cache',
            '/var/tmp']
    configDir=selectDirectory(dirs)
    if configDir == ENV['HOME']
      configDir = configDir + '/.geotoad'
    elsif configDir !~ /geotoad/i
      configDir = configDir + "/GeoToad"
    end
    debug "#{configDir} is being used for config"
    FileUtils::mkdir_p(configDir, :mode => 0700)
    return configDir
  end

  def findDataDir
    dirs = [
      "data",
      "../data",
      File.dirname(__FILE__) + "/../data",
      "#{ENV['COMMONPROGRAMFILES']}/GeoToad/data",
      "#{ENV['PROGRAMFILES']}/GeoToad/data",
      "/usr/share/geotoad",
      "/usr/local/share/geotoad"
    ]
    dirs.each {|dir|
      if File.exist?("#{dir}/funfactor.txt")
        return dir
      end
    }
    puts " ***  Could not identify data directory."
    puts " ***  If GeoToad crashes, you may want to run from the install directory."
    return "../data"
  end

  ## finds a place to put temp files on the system ###################################
  def findOutputDir
    # find out where we want our cache #############################
    dirs = [
      ENV['GEO_DIR'],
      "#{ENV['HOME']}/Desktop",
      "#{ENV['HOME']}/Skrivbord",
      "#{ENV['USERPROFILE']}/Desktop",
      ENV['HOME']
    ]

    outputDir=selectDirectory(dirs)
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

end
