# $Id$
require 'fileutils'

module Common
  
  def parseDate(date)
    timestamp = nil
    case date
    when /Today/
      days_ago=0
    when /Yesterday/
      days_ago=1
    when /(\d)+ days ago/
      days_ago=$1.to_i
    when /^\d+[ \/]\w+[ \/]\d+/
      timestamp = Time.parse(date)
    else
      displayWarning "Could not parse date: #{date}"
      return nil
    end
    if not timestamp and days_ago
      timestamp = Time.now - (days_ago * 3600 * 24)
    end
    return timestamp    
  end
  
  def daysAgo(timestamp)
    return (Time.now - timestamp).to_i / 86400    
  end

  ## finds a place to put temp files on the system ###################################
  def selectDirectory(dirs)
    selected=nil
    dirs.compact.each do |dir|
      begin
        if ((File.stat(dir).directory?) && (File.stat(dir).writable?))
          selected=dir.dup
          break
        end
      rescue
      end
    end
  
    # fall back on the current directory if everything else fails!
    if (! selected)
      selected=Dir.pwd
    else
      selected.gsub!(/\\/, '/')
    end
    return selected
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
      return cacheDir
    end
  
    ## finds a place to put temp files on the system ###################################
  end
  def findConfigDir
    # find out where we want our cache #############################
    configDir=selectDirectory([ ENV['GEO_DIR'], "#{ENV['HOME']}/Library/Preferences", 
        "#{ENV['USERPROFILE']}/Documents and Settings", ENV['HOME'], "C:/temp/", "C:/windows/temp", "/var/cache", "/var/tmp" ])
  
    if configDir == ENV['HOME']
      configDir=configDir + '/.geotoad'
    else
      configDir=configDir + "/GeoToad"
    end
    debug "#{configDir} is being used for config"
    FileUtils::mkdir_p(configDir)
    return configDir
  end

  ## finds a place to put temp files on the system ###################################
  def findOutputDir
    # find out where we want our cache #############################
    outputDir=selectDirectory([ ENV['GEO_DIR'], "#{ENV['HOME']}/Desktop", 
        "#{ENV['USERPROFILE']}/Desktop", ENV['HOME'] ])
  
    debug "#{outputDir} is being used as the default output directory"
    FileUtils::mkdir_p(outputDir)
    return outputDir
  end
end
