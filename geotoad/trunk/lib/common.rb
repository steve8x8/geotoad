# $Id$

module Common
    
    ## finds a place to put temp files on the system ###################################
    def selectDirectory(dirs)
        dir=nil
        debug "Searching directories: #{dirs.join(':')}"
        dirs.compact.each do |dir|
            begin
                debug "Checking if #{dir} is suitable"
                if ((File.stat(dir).directory?) && (File.stat(dir).writable?))
                    break
                end
            rescue
            end
        end
        
        # fall back on the current directory if everything else fails!
        if (! dir)
            dir=Dir.pwd
        else
            dir.gsub!(/\\/, '/')
        end
        debug "Found #{dir}"
        return dir
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
        return configDir
    end
    
    ## finds a place to put temp files on the system ###################################
    def findOutputDir
        # find out where we want our cache #############################
        outputDir=selectDirectory([ ENV['GEO_DIR'], "#{ENV['HOME']}/Desktop", 
			"#{ENV['USERPROFILE']}/Desktop", ENV['HOME'] ])
        
        debug "#{outputDir} is being used as the default output directory"
        return outputDir
    end
end
