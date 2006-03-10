# $Id$

module Common
    
    ## finds a place to put temp files on the system ###################################
    def findTempDir
        # find out where we want our cache #############################
        tempDir = nil
        tryTempDirs = [ ENV['GEO_TEMP'], "#{ENV['HOME']}/Library/Caches", ENV['TEMP'],
			"C:/temp/", "C:/windows/temp", "C:/tmp/", ENV['TMP'], "/var/cache", "/var/tmp" ];
        
        # get rid of the Nils'
        tryTempDirs.compact!
        
        tryTempDirs.each { |dir|
            begin
                debug "Checking if #{dir} is suitable"
                if ((File.stat(dir).directory?) && (File.stat(dir).writable?))
                    tempDir=dir + "/GeoToad"
                    break
                end
            rescue
            end
        }
        
        # probably what we fallback to in most UNIX's.
        if ((! tempDir) && ENV['HOME'])
            tempDir=ENV['HOME'] + '/.geotoad'
        end
        
        # Convert DOS C:// to C:\
        if tempDir
            tempDir.gsub!(/\\/, '/')
        end
        debug "#{tempDir} is being used for temp"
        return tempDir
    end
    
     ## finds a place to put temp files on the system ###################################
    def findConfigDir
        # find out where we want our cache #############################
        configDir = nil
        tryconfigDirs = [ ENV['GEO_CONFIG'], "#{ENV['HOME']}/Library/Preferences", 
			"#{ENV['USERPROFILE']}/Documents and Settings", "C:/temp/", "C:/windows/temp", "/var/cache", "/var/tmp" ];
        
        # get rid of the Nils'
        tryconfigDirs.compact!
        
        tryconfigDirs.each { |dir|
            begin
                debug "Checking if #{dir} is suitable"
                if ((File.stat(dir).directory?) && (File.stat(dir).writable?))
                    configDir=dir + "/GeoToad"
                    break
                end
            rescue
            end
        }
        
        # probably what we fallback to in most UNIX's.
        if ((! configDir) && ENV['HOME'])
            configDir=ENV['HOME'] + '/.geotoad'
        end
        
        # Convert DOS C:// to C:\
        if configDir
            configDir.gsub!(/\\/, '/')
        end
        debug "#{configDir} is being used for configuration"
        return configDir
    end
end
