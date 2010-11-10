# $Id$
require 'fileutils'

module Common

  def parseDate(date)
    debug "parsing date: [#{date}]"
    timestamp = nil
    case date
    when /Today/
      days_ago=0
    when /Yesterday/
      days_ago=1
    when /(\d)+ days ago/
      days_ago=$1.to_i
    when /^(\d+)\/(\d+)\/(\d{4})$/
      debug "Looks like a date: year=#{$3} month=#{$1}, date=#{$2}"
      if $3.to_i < 1970
        debug "The year appears to be earlier than 1970. Patching to 1970."
        year = 1970
      else
        year = $3
      end
      timestamp = Time.local(year, $1, $2)
    when /^\d+[ \/]\w+[ \/]\d+/
      timestamp = Time.parse(date)
    when 'N/A'
      return nil
    else
      displayWarning "Could not parse date: #{date}"
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
      warn "Could not convert timestamp '#{timestamp}' to Time object."
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
      "/usr/share/geotoad",
      "/usr/local/share/geotoad"
    ]
    dirs.each {|dir|
      if File.exist?("#{dir}/funfactor.txt")
        return dir
      end
    }
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
end
